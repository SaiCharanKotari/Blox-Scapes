--!strict
-- GravityResolver: Handles tile fall shifts, deterministic top refills, and cascade safety guards
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
type CascadeStep = BoardTypes.CascadeStep
type SpecialPieceType = BoardTypes.SpecialPieceType

local GravityResolver = {}

export type RNG = {
    NextInteger: (self: any, min: number, max: number) -> number,
    NextNumber: (self: any) -> number,
}

-- Default pseudo-random generator if none is injected
local function createDefaultRNG(): RNG
    return {
        NextInteger = function(_, min: number, max: number)
            return math.random(min, max)
        end,
        NextNumber = function(_)
            return math.random()
        end,
    }
end

-- Simulates gravity: tiles fall downward into empty spaces within their column
-- Returns array of shift moves: { from: Coord, to: Coord, tile: Tile }
function GravityResolver.applyGravity(
    grid: Grid,
    width: number,
    height: number,
    emptySlots: { [string]: boolean }? -- permanent holes/cutouts
): { { from: Coord, to: Coord, tile: Tile } }
    local shifts: { { from: Coord, to: Coord, tile: Tile } } = {}

    for x = 1, width do
        -- Iterate upwards from bottom of board
        for y = height, 1, -1 do
            local key = BoardCoord.toKey(x, y)
            local isCutout = emptySlots and emptySlots[key]

            if not isCutout and BoardCoord.getTile(grid, x, y) == nil then
                -- Look for the closest tile above this row to drop down
                local foundY: number? = nil
                for searchY = y - 1, 1, -1 do
                    local searchKey = BoardCoord.toKey(x, searchY)
                    if not (emptySlots and emptySlots[searchKey]) then
                        local tileAbove = BoardCoord.getTile(grid, x, searchY)
                        if tileAbove and tileAbove.blocker ~= "Stone" then
                            foundY = searchY
                            break
                        end
                    end
                end

                if foundY then
                    local fallingTile = BoardCoord.getTile(grid, x, foundY)
                    if fallingTile then
                        BoardCoord.setTile(grid, x, y, fallingTile)
                        BoardCoord.setTile(grid, x, foundY, nil)

                        table.insert(shifts, {
                            from = BoardCoord.create(x, foundY),
                            to = BoardCoord.create(x, y),
                            tile = fallingTile,
                        })
                    end
                end
            end
        end
    end

    return shifts
end

-- Fills all remaining empty slots at the top with fresh deterministic tiles
function GravityResolver.refillEmptySlots(
    grid: Grid,
    width: number,
    height: number,
    allowedColors: { TileColor },
    rng: any,
    idGenerator: () -> string,
    emptySlots: { [string]: boolean }?
): { { coord: Coord, tile: Tile } }
    local refilled: { { coord: Coord, tile: Tile } } = {}
    local actualRNG: RNG = rng or createDefaultRNG()

    for y = 1, height do
        for x = 1, width do
            local key = BoardCoord.toKey(x, y)
            local isCutout = emptySlots and emptySlots[key]

            if not isCutout and BoardCoord.getTile(grid, x, y) == nil then
                local colorIndex = actualRNG:NextInteger(1, #allowedColors)
                local chosenColor = allowedColors[colorIndex]

                local newTile: Tile = {
                    id = idGenerator(),
                    color = chosenColor,
                    blocker = nil,
                    special = nil,
                    isMatched = false,
                }

                BoardCoord.setTile(grid, x, y, newTile)
                table.insert(refilled, {
                    coord = BoardCoord.create(x, y),
                    tile = newTile,
                })
            end
        end
    end

    return refilled
end

return GravityResolver
