--!strict
-- BoardCoord: Strict coordinate utilities and grid access helpers for Project Bloomtrail
-- Internal grid indexing convention: grid[y][x] (1-indexed row y, column x)

local BoardTypes
if typeof(script) == "Instance" and script.Parent then
    BoardTypes = require(script.Parent.Parent.Types.BoardTypes)
else
    BoardTypes = require("../Types/BoardTypes")
end

type Coord = BoardTypes.Coord
type Tile = BoardTypes.Tile
type Grid = BoardTypes.Grid

local BoardCoord = {}

function BoardCoord.create(x: number, y: number): Coord
    return { x = x, y = y }
end

function BoardCoord.equals(c1: Coord, c2: Coord): boolean
    return c1.x == c2.x and c1.y == c2.y
end

function BoardCoord.isValid(x: number, y: number, width: number, height: number): boolean
    return x >= 1 and x <= width and y >= 1 and y <= height
end

function BoardCoord.isAdjacent(c1: Coord, c2: Coord): boolean
    local dx = math.abs(c1.x - c2.x)
    local dy = math.abs(c1.y - c2.y)
    return (dx == 1 and dy == 0) or (dx == 0 and dy == 1)
end

function BoardCoord.toIndex(x: number, y: number, width: number): number
    return (y - 1) * width + x
end

function BoardCoord.fromIndex(index: number, width: number): Coord
    local y = math.floor((index - 1) / width) + 1
    local x = ((index - 1) % width) + 1
    return { x = x, y = y }
end

function BoardCoord.toKey(x: number, y: number): string
    return x .. "," .. y
end

function BoardCoord.fromKey(key: string): Coord
    local parts = string.split(key, ",")
    return { x = tonumber(parts[1]) or 1, y = tonumber(parts[2]) or 1 }
end

function BoardCoord.getTile(grid: Grid, x: number, y: number): Tile?
    local row = grid[y]
    if not row then
        return nil
    end
    return row[x]
end

function BoardCoord.setTile(grid: Grid, x: number, y: number, tile: Tile?): ()
    if not grid[y] then
        grid[y] = {}
    end
    grid[y][x] = tile
end

function BoardCoord.createEmptyGrid(width: number, height: number): Grid
    local grid: Grid = {}
    for y = 1, height do
        grid[y] = {}
        for x = 1, width do
            grid[y][x] = nil
        end
    end
    return grid
end

function BoardCoord.cloneGrid(grid: Grid, width: number, height: number): Grid
    local copy: Grid = {}
    for y = 1, height do
        copy[y] = {}
        local row = grid[y]
        if row then
            for x = 1, width do
                local tile = row[x]
                if tile then
                    copy[y][x] = {
                        id = tile.id,
                        color = tile.color,
                        blocker = tile.blocker,
                        special = tile.special,
                        isMatched = tile.isMatched,
                    }
                else
                    copy[y][x] = nil
                end
            end
        end
    end
    return copy
end

return BoardCoord
