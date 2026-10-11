--!strict
-- MatchDetector: Match detection, intersection merging, and special piece creation rules
-- Decoupled pure Luau engine module

local BoardTypes
local BoardCoord
if typeof(script) == "Instance" and script.Parent then
    BoardTypes = require(script.Parent.Parent.Types.BoardTypes)
    BoardCoord = require(script.Parent.Parent.Utils.BoardCoord)
else
    BoardTypes = require("../Types/BoardTypes")
    BoardCoord = require("../Utils/BoardCoord")
end

type Coord = BoardTypes.Coord
type Tile = BoardTypes.Tile
type Grid = BoardTypes.Grid
type TileColor = BoardTypes.TileColor
type MatchGroup = BoardTypes.MatchGroup
type SpecialPieceType = BoardTypes.SpecialPieceType

local MatchDetector = {}

type RawLine = {
    color: TileColor,
    coords: { Coord },
    direction: "H" | "V",
}

-- Finds all horizontal and vertical lines of 3 or more matching colors
function MatchDetector.findRawLines(grid: Grid, width: number, height: number): { RawLine }
    local lines: { RawLine } = {}

    -- Horizontal scan
    for y = 1, height do
        local startX = 1
        while startX <= width do
            local startTile = BoardCoord.getTile(grid, startX, y)
            if startTile and startTile.color and startTile.blocker == nil then
                local color = startTile.color
                local endX = startX
                while endX + 1 <= width do
                    local nextTile = BoardCoord.getTile(grid, endX + 1, y)
                    if nextTile and nextTile.color == color and nextTile.blocker == nil then
                        endX += 1
                    else
                        break
                    end
                end

                local length = endX - startX + 1
                if length >= 3 then
                    local coords: { Coord } = {}
                    for x = startX, endX do
                        table.insert(coords, BoardCoord.create(x, y))
                    end
                    table.insert(lines, {
                        color = color,
                        coords = coords,
                        direction = "H",
                    })
                end
                startX = endX + 1
            else
                startX += 1
            end
        end
    end

    -- Vertical scan
    for x = 1, width do
        local startY = 1
        while startY <= height do
            local startTile = BoardCoord.getTile(grid, x, startY)
            if startTile and startTile.color and startTile.blocker == nil then
                local color = startTile.color
                local endY = startY
                while endY + 1 <= height do
                    local nextTile = BoardCoord.getTile(grid, x, endY + 1)
                    if nextTile and nextTile.color == color and nextTile.blocker == nil then
                        endY += 1
                    else
                        break
                    end
                end

                local length = endY - startY + 1
                if length >= 3 then
                    local coords: { Coord } = {}
                    for y = startY, endY do
                        table.insert(coords, BoardCoord.create(x, y))
                    end
                    table.insert(lines, {
                        color = color,
                        coords = coords,
                        direction = "V",
                    })
                end
                startY = endY + 1
            else
                startY += 1
            end
        end
    end

    return lines
end

-- Merges intersecting lines (L/T/+ shapes) into unified MatchGroups without duplicate coordinates
function MatchDetector.findMatches(grid: Grid, width: number, height: number, swapTarget: Coord?): { MatchGroup }
    local rawLines = MatchDetector.findRawLines(grid, width, height)
    if #rawLines == 0 then
        return {}
    end

    -- Disjoint-set / graph clustering for lines of identical color sharing coordinates
    local lineClusters: { { lines: { RawLine }, coordSet: { [string]: boolean }, intersections: { Coord } } } = {}

    for _, line in ipairs(rawLines) do
        local matchingClusterIndices: { number } = {}

        for cIndex, cluster in ipairs(lineClusters) do
            if cluster.lines[1].color == line.color then
                -- Check for coordinate intersection
                local intersects = false
                for _, coord in ipairs(line.coords) do
                    local key = BoardCoord.toKey(coord.x, coord.y)
                    if cluster.coordSet[key] then
                        intersects = true
                        table.insert(cluster.intersections, coord)
                        break
                    end
                end
                if intersects then
                    table.insert(matchingClusterIndices, cIndex)
                end
            end
        end

        if #matchingClusterIndices == 0 then
            -- Create a new cluster
            local coordSet: { [string]: boolean } = {}
            for _, coord in ipairs(line.coords) do
                coordSet[BoardCoord.toKey(coord.x, coord.y)] = true
            end
            table.insert(lineClusters, {
                lines = { line },
                coordSet = coordSet,
                intersections = {},
            })
        elseif #matchingClusterIndices == 1 then
            -- Merge into existing cluster
            local cluster = lineClusters[matchingClusterIndices[1]]
            table.insert(cluster.lines, line)
            for _, coord in ipairs(line.coords) do
                local key = BoardCoord.toKey(coord.x, coord.y)
                cluster.coordSet[key] = true
            end
        else
            -- Multiple clusters now connected by this line; merge them together
            local primaryCluster = lineClusters[matchingClusterIndices[1]]
            table.insert(primaryCluster.lines, line)
            for _, coord in ipairs(line.coords) do
                primaryCluster.coordSet[BoardCoord.toKey(coord.x, coord.y)] = true
            end

            -- Merge subsequent clusters into primary (in reverse order for safe removal)
            for i = #matchingClusterIndices, 2, -1 do
                local otherIndex = matchingClusterIndices[i]
                local otherCluster = lineClusters[otherIndex]
                for _, otherLine in ipairs(otherCluster.lines) do
                    table.insert(primaryCluster.lines, otherLine)
                end
                for key in pairs(otherCluster.coordSet) do
                    primaryCluster.coordSet[key] = true
                end
                for _, inter in ipairs(otherCluster.intersections) do
                    table.insert(primaryCluster.intersections, inter)
                end
                table.remove(lineClusters, otherIndex)
            end
        end
    end

    -- Construct unified MatchGroups
    local matchGroups: { MatchGroup } = {}

    for _, cluster in ipairs(lineClusters) do
        local color = cluster.lines[1].color
        local coords: { Coord } = {}
        for key in pairs(cluster.coordSet) do
            table.insert(coords, BoardCoord.fromKey(key))
        end

        local count = #coords
        local isSpecial = count >= 4
        local specialType: SpecialPieceType? = nil
        local spawnCoord: Coord? = nil

        if isSpecial then
            specialType = "BlossomBomb"

            -- Spawn coordinate selection prioritization:
            -- 1. If player initiated swap and the target is in the match group, spawn there.
            if swapTarget and cluster.coordSet[BoardCoord.toKey(swapTarget.x, swapTarget.y)] then
                spawnCoord = swapTarget
            -- 2. If it's an intersecting L/T match, spawn at the intersection point.
            elseif #cluster.intersections > 0 then
                spawnCoord = cluster.intersections[1]
            -- 3. Otherwise pick the median / center tile of the line.
            else
                local midIndex = math.ceil(count / 2)
                spawnCoord = coords[midIndex]
            end
        end

        table.insert(matchGroups, {
            color = color,
            coords = coords,
            isSpecial = isSpecial,
            specialType = specialType,
            spawnCoord = spawnCoord,
        })
    end

    return matchGroups
end

-- Returns coordinates within a 3x3 radius around centerCoord
function MatchDetector.getBombBlastArea(center: Coord, width: number, height: number): { Coord }
    local blastCoords: { Coord } = {}
    for dy = -1, 1 do
        for dx = -1, 1 do
            local nx = center.x + dx
            local ny = center.y + dy
            if BoardCoord.isValid(nx, ny, width, height) then
                table.insert(blastCoords, BoardCoord.create(nx, ny))
            end
        end
    end
    return blastCoords
end

return MatchDetector
