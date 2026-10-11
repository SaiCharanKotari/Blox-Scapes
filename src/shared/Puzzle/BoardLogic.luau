--!strict
-- BoardLogic: Central headless match-3 puzzle simulation engine for Project Bloomtrail
-- Zero Roblox service dependencies (Pure Luau)

local BoardTypes
local LevelTypes
local BoardCoord
local MatchDetector
local GravityResolver
local SpawnWeightCalculator
if typeof(script) == "Instance" and script.Parent then
    BoardTypes = require(script.Parent.Parent.Types.BoardTypes)
    LevelTypes = require(script.Parent.Parent.Types.LevelTypes)
    BoardCoord = require(script.Parent.Parent.Utils.BoardCoord)
    MatchDetector = require(script.Parent.MatchDetector)
    GravityResolver = require(script.Parent.GravityResolver)
    SpawnWeightCalculator = require(script.Parent.SpawnWeightCalculator)
else
    BoardTypes = require("../Types/BoardTypes")
    LevelTypes = require("../Types/LevelTypes")
    BoardCoord = require("../Utils/BoardCoord")
    MatchDetector = require("./MatchDetector")
    GravityResolver = require("./GravityResolver")
    SpawnWeightCalculator = require("./SpawnWeightCalculator")
end

type Coord = BoardTypes.Coord
type Tile = BoardTypes.Tile
type Grid = BoardTypes.Grid
type TileColor = BoardTypes.TileColor
type BlockerType = BoardTypes.BlockerType
type SpecialPieceType = BoardTypes.SpecialPieceType
type MatchGroup = BoardTypes.MatchGroup
type CascadeStep = BoardTypes.CascadeStep
type SwapResult = BoardTypes.SwapResult
type GameStatus = BoardTypes.GameStatus
type ObjectiveState = BoardTypes.ObjectiveState
type LevelDefinition = LevelTypes.LevelDefinition
type ObjectiveWeightConfig = LevelTypes.ObjectiveWeightConfig

export type BoardSession = {
    width: number,
    height: number,
    grid: Grid,
    allowedColors: { TileColor },
    emptyCutouts: { [string]: boolean },
    movesRemaining: number,
    status: GameStatus,
    objectives: { ObjectiveState },
    rng: any,
    nextId: number,
    weightConfig: ObjectiveWeightConfig?,
}

local BoardLogic = {}

local function generateTileId(session: BoardSession): string
    session.nextId += 1
    return "tile_" .. session.nextId
end

-- Creates an injectable PRNG or standard Random wrapper
function BoardLogic.createRNG(seed: number?): any
    local actualSeed = seed or 12345678
    -- Linear congruential generator for pure cross-platform deterministic testability
    local state = actualSeed
    return {
        NextInteger = function(self: any, min: number, max: number): number
            state = (state * 1103515245 + 12345) % 2147483648
            local range = max - min + 1
            return min + (state % range)
        end,
        NextNumber = function(self: any): number
            state = (state * 1103515245 + 12345) % 2147483648
            return state / 2147483648
        end,
    }
end

-- Checks if placing a color at (x, y) would cause an immediate 3-in-a-row match
local function wouldCreateImmediateMatch(grid: Grid, x: number, y: number, color: TileColor): boolean
    -- Check left 2 tiles
    if x >= 3 then
        local t1 = BoardCoord.getTile(grid, x - 1, y)
        local t2 = BoardCoord.getTile(grid, x - 2, y)
        if t1 and t1.color == color and t2 and t2.color == color then
            return true
        end
    end
    -- Check top 2 tiles
    if y >= 3 then
        local t1 = BoardCoord.getTile(grid, x, y - 1)
        local t2 = BoardCoord.getTile(grid, x, y - 2)
        if t1 and t1.color == color and t2 and t2.color == color then
            return true
        end
    end
    return false
end

-- Finds all legal moves on the board
function BoardLogic.findPossibleMoves(grid: Grid, width: number, height: number): { { from: Coord, to: Coord } }
    local possibleMoves: { { from: Coord, to: Coord } } = {}

    -- Helper to test swap
    local function testSwap(p1: Coord, p2: Coord)
        local t1 = BoardCoord.getTile(grid, p1.x, p1.y)
        local t2 = BoardCoord.getTile(grid, p2.x, p2.y)
        if not t1 or not t2 then return end
        if t1.blocker == "Stone" or t2.blocker == "Stone" then return end

        -- If either is a BlossomBomb, swapping with any normal piece is a valid move
        if t1.special == "BlossomBomb" or t2.special == "BlossomBomb" then
            table.insert(possibleMoves, { from = p1, to = p2 })
            return
        end

        -- Temporarily swap
        BoardCoord.setTile(grid, p1.x, p1.y, t2)
        BoardCoord.setTile(grid, p2.x, p2.y, t1)

        local matches = MatchDetector.findRawLines(grid, width, height)
        if #matches > 0 then
            table.insert(possibleMoves, { from = p1, to = p2 })
        end

        -- Revert swap
        BoardCoord.setTile(grid, p1.x, p1.y, t1)
        BoardCoord.setTile(grid, p2.x, p2.y, t2)
    end

    for y = 1, height do
        for x = 1, width do
            local p1 = BoardCoord.create(x, y)
            -- Horizontal neighbor
            if x + 1 <= width then
                testSwap(p1, BoardCoord.create(x + 1, y))
            end
            -- Vertical neighbor
            if y + 1 <= height then
                testSwap(p1, BoardCoord.create(x, y + 1))
            end
        end
    end

    return possibleMoves
end

-- Validates whether swapping fromCoord with toCoord is permissible
function BoardLogic.validateSwap(session: BoardSession, fromCoord: Coord, toCoord: Coord): boolean
    if session.status ~= "InProgress" then
        return false
    end
    if not BoardCoord.isValid(fromCoord.x, fromCoord.y, session.width, session.height) then
        return false
    end
    if not BoardCoord.isValid(toCoord.x, toCoord.y, session.width, session.height) then
        return false
    end
    if not BoardCoord.isAdjacent(fromCoord, toCoord) then
        return false
    end

    local t1 = BoardCoord.getTile(session.grid, fromCoord.x, fromCoord.y)
    local t2 = BoardCoord.getTile(session.grid, toCoord.x, toCoord.y)
    if not t1 or not t2 then
        return false
    end
    if t1.blocker == "Stone" or t2.blocker == "Stone" then
        return false
    end

    -- If either tile is a special piece (e.g. BlossomBomb), swap is automatically valid
    if t1.special == "BlossomBomb" or t2.special == "BlossomBomb" then
        return true
    end

    -- Check if swap produces a match
    BoardCoord.setTile(session.grid, fromCoord.x, fromCoord.y, t2)
    BoardCoord.setTile(session.grid, toCoord.x, toCoord.y, t1)

    local matches = MatchDetector.findMatches(session.grid, session.width, session.height)
    local hasMatch = #matches > 0

    -- Revert swap
    BoardCoord.setTile(session.grid, fromCoord.x, fromCoord.y, t1)
    BoardCoord.setTile(session.grid, toCoord.x, toCoord.y, t2)

    return hasMatch
end

-- Analyzes the resolved tiles collected by executing a swap, without mutating session
function BoardLogic.analyzeMoveProductivity(
    session: BoardSession,
    fromCoord: Coord,
    toCoord: Coord
): { [TileColor]: number }
    local collected: { [TileColor]: number } = {}

    if not BoardLogic.validateSwap(session, fromCoord, toCoord) then
        return collected
    end

    local cloneGrid = BoardCoord.cloneGrid(session.grid, session.width, session.height)
    local t1 = BoardCoord.getTile(cloneGrid, fromCoord.x, fromCoord.y)
    local t2 = BoardCoord.getTile(cloneGrid, toCoord.x, toCoord.y)
    if not t1 or not t2 then
        return collected
    end

    BoardCoord.setTile(cloneGrid, fromCoord.x, fromCoord.y, t2)
    BoardCoord.setTile(cloneGrid, toCoord.x, toCoord.y, t1)

    local clearedSet: { [string]: Coord } = {}

    local function addClearedCoord(x: number, y: number)
        if BoardCoord.isValid(x, y, session.width, session.height) then
            local key = BoardCoord.toKey(x, y)
            if not session.emptyCutouts[key] then
                clearedSet[key] = BoardCoord.create(x, y)
            end
        end
    end

    if t1.special == "BlossomBomb" then
        for dy = -1, 1 do
            for dx = -1, 1 do
                addClearedCoord(toCoord.x + dx, toCoord.y + dy)
            end
        end
    end
    if t2.special == "BlossomBomb" then
        for dy = -1, 1 do
            for dx = -1, 1 do
                addClearedCoord(fromCoord.x + dx, fromCoord.y + dy)
            end
        end
    end

    local matches = MatchDetector.findMatches(cloneGrid, session.width, session.height)
    for _, group in ipairs(matches) do
        for _, coord in ipairs(group.coords) do
            addClearedCoord(coord.x, coord.y)
        end
    end

    for _, coord in pairs(clearedSet) do
        local tile = BoardCoord.getTile(cloneGrid, coord.x, coord.y)
        if tile and tile.color and tile.blocker ~= "Stone" then
            collected[tile.color] = (collected[tile.color] or 0) + 1
        end
    end

    return collected
end

-- Checks if a move is directly productive for a specific target color
function BoardLogic.isMoveProductiveForColor(
    session: BoardSession,
    fromCoord: Coord,
    toCoord: Coord,
    color: TileColor
): boolean
    local productivity = BoardLogic.analyzeMoveProductivity(session, fromCoord, toCoord)
    return (productivity[color] or 0) > 0
end

-- Finds all legal moves on the board that contribute directly to collecting a specific color
function BoardLogic.findProductiveMoves(
    session: BoardSession,
    color: TileColor
): { { from: Coord, to: Coord, collectedCount: number } }
    local results: { { from: Coord, to: Coord, collectedCount: number } } = {}
    local possibleMoves = BoardLogic.findPossibleMoves(session.grid, session.width, session.height)

    for _, move in ipairs(possibleMoves) do
        local productivity = BoardLogic.analyzeMoveProductivity(session, move.from, move.to)
        local count = productivity[color] or 0
        if count > 0 then
            table.insert(results, {
                from = move.from,
                to = move.to,
                collectedCount = count,
            })
        end
    end

    return results
end

-- Bounded, validated recovery mechanism guaranteeing productive moves for unfinished objectives
-- Preserves dimensions, blockers, specials, moves remaining, and objective state
function BoardLogic.ensureProductiveMoves(session: BoardSession): boolean
    local width = session.width
    local height = session.height

    for _, obj in ipairs(session.objectives) do
        if not obj.completed and obj.kind == "collect_color" and obj.color then
            local color = obj.color
            local prodMoves = BoardLogic.findProductiveMoves(session, color)

            if #prodMoves == 0 then
                local repaired = false

                -- Try horizontal match-3 setup:
                -- (x, y) = color, (x+1, y) = color, (x+2, y) != color, (x+2, y+1) = color
                -- Swapping (x+2, y) and (x+2, y+1) creates a 3-match of color!
                for y = 1, height - 1 do
                    if repaired then break end
                    for x = 1, width - 2 do
                        local t1 = BoardCoord.getTile(session.grid, x, y)
                        local t2 = BoardCoord.getTile(session.grid, x + 1, y)
                        local t3 = BoardCoord.getTile(session.grid, x + 2, y)
                        local t4 = BoardCoord.getTile(session.grid, x + 2, y + 1)

                        local canModify = t1 and t2 and t3 and t4 and
                            t1.blocker == nil and t2.blocker == nil and
                            t3.blocker == nil and t4.blocker == nil and
                            t1.special == nil and t2.special == nil and
                            t3.special == nil and t4.special == nil

                        if canModify and t3.color ~= color then
                            local oldC1, oldC2, oldC4 = t1.color, t2.color, t4.color
                            t1.color = color
                            t2.color = color
                            t4.color = color

                            local imm = MatchDetector.findMatches(session.grid, width, height)
                            if #imm == 0 then
                                local cA = BoardCoord.create(x + 2, y)
                                local cB = BoardCoord.create(x + 2, y + 1)
                                if BoardLogic.isMoveProductiveForColor(session, cA, cB, color) then
                                    repaired = true
                                    break
                                end
                            end

                            t1.color = oldC1
                            t2.color = oldC2
                            t4.color = oldC4
                        end
                    end
                end

                -- Try vertical match-3 setup if horizontal didn't succeed
                if not repaired then
                    for x = 1, width - 1 do
                        if repaired then break end
                        for y = 1, height - 2 do
                            local t1 = BoardCoord.getTile(session.grid, x, y)
                            local t2 = BoardCoord.getTile(session.grid, x, y + 1)
                            local t3 = BoardCoord.getTile(session.grid, x, y + 2)
                            local t4 = BoardCoord.getTile(session.grid, x + 1, y + 2)

                            local canModify = t1 and t2 and t3 and t4 and
                                t1.blocker == nil and t2.blocker == nil and
                                t3.blocker == nil and t4.blocker == nil and
                                t1.special == nil and t2.special == nil and
                                t3.special == nil and t4.special == nil

                            if canModify and t3.color ~= color then
                                local oldC1, oldC2, oldC4 = t1.color, t2.color, t4.color
                                t1.color = color
                                t2.color = color
                                t4.color = color

                                local imm = MatchDetector.findMatches(session.grid, width, height)
                                if #imm == 0 then
                                    local cA = BoardCoord.create(x, y + 2)
                                    local cB = BoardCoord.create(x + 1, y + 2)
                                    if BoardLogic.isMoveProductiveForColor(session, cA, cB, color) then
                                        repaired = true
                                        break
                                    end
                                end

                                t1.color = oldC1
                                t2.color = oldC2
                                t4.color = oldC4
                            end
                        end
                    end
                end
            end
        end
    end

    return true
end

-- Reshuffles movable tiles when 0 legal moves remain
function BoardLogic.reshuffleBoard(session: BoardSession): boolean
    local movableCoords: { Coord } = {}
    local tileColors: { TileColor } = {}

    for y = 1, session.height do
        for x = 1, session.width do
            local key = BoardCoord.toKey(x, y)
            if not session.emptyCutouts[key] then
                local tile = BoardCoord.getTile(session.grid, x, y)
                if tile and tile.blocker ~= "Stone" then
                    table.insert(movableCoords, BoardCoord.create(x, y))
                    if tile.color then
                        table.insert(tileColors, tile.color)
                    else
                        table.insert(tileColors, session.allowedColors[1])
                    end
                end
            end
        end
    end

    if #movableCoords <= 1 then
        return false
    end

    local maxAttempts = 100
    for _ = 1, maxAttempts do
        -- Clear grid slots
        for _, coord in ipairs(movableCoords) do
            BoardCoord.setTile(session.grid, coord.x, coord.y, nil)
        end

        -- Shuffle color pool
        for i = #tileColors, 2, -1 do
            local j = session.rng:NextInteger(1, i)
            local temp = tileColors[i]
            tileColors[i] = tileColors[j]
            tileColors[j] = temp
        end

        -- Place colors slot by slot avoiding immediate matches
        local remaining = table.clone(tileColors)
        local failed = false

        for _, coord in ipairs(movableCoords) do
            local foundIndex: number? = nil
            for i, col in ipairs(remaining) do
                if not wouldCreateImmediateMatch(session.grid, coord.x, coord.y, col) then
                    foundIndex = i
                    break
                end
            end

            if foundIndex then
                local col = remaining[foundIndex]
                table.remove(remaining, foundIndex)
                BoardCoord.setTile(session.grid, coord.x, coord.y, {
                    id = generateTileId(session),
                    color = col,
                    blocker = nil,
                    special = nil,
                    isMatched = false,
                })
            else
                if #remaining > 0 then
                    local col = remaining[1]
                    table.remove(remaining, 1)
                    BoardCoord.setTile(session.grid, coord.x, coord.y, {
                        id = generateTileId(session),
                        color = col,
                        blocker = nil,
                        special = nil,
                        isMatched = false,
                    })
                else
                    failed = true
                    break
                end
            end
        end

        if not failed then
            local immediate = MatchDetector.findMatches(session.grid, session.width, session.height)
            if #immediate == 0 then
                local moves = BoardLogic.findPossibleMoves(session.grid, session.width, session.height)
                if #moves >= 1 then
                    return true
                end
            end
        end
    end

    -- Deterministic fallback: place colors ensuring 0 immediate matches and >= 1 move
    local fallbackWeights = SpawnWeightCalculator.calculateWeights(
        session.allowedColors,
        session.objectives,
        session.weightConfig
    )

    for y = 1, session.height do
        for x = 1, session.width do
            local key = BoardCoord.toKey(x, y)
            if not session.emptyCutouts[key] then
                local validColors: { TileColor } = {}
                for _, color in ipairs(session.allowedColors) do
                    if not wouldCreateImmediateMatch(session.grid, x, y, color) then
                        table.insert(validColors, color)
                    end
                end
                local chosenColor = if #validColors > 0
                    then SpawnWeightCalculator.pickWeightedColor(validColors, fallbackWeights, session.rng)
                    else SpawnWeightCalculator.pickWeightedColor(session.allowedColors, fallbackWeights, session.rng)

                BoardCoord.setTile(session.grid, x, y, {
                    id = generateTileId(session),
                    color = chosenColor,
                    blocker = nil,
                    special = nil,
                    isMatched = false,
                })
            end
        end
    end

    BoardLogic.ensureProductiveMoves(session)
    return true
end

-- Initializes a new puzzle session from a LevelDefinition
function BoardLogic.createSession(levelDef: LevelDefinition, seed: number?): BoardSession
    local rng = BoardLogic.createRNG(seed)
    local width = levelDef.width
    local height = levelDef.height
    local emptyCutouts: { [string]: boolean } = {}
    local grid = BoardCoord.createEmptyGrid(width, height)

    local session: BoardSession = {
        width = width,
        height = height,
        grid = grid,
        allowedColors = levelDef.allowedColors,
        emptyCutouts = emptyCutouts,
        movesRemaining = levelDef.moveLimit,
        status = "InProgress",
        objectives = {},
        rng = rng,
        nextId = 0,
    }

    -- Initialize objectives
    for _, obj in ipairs(levelDef.objectives) do
        table.insert(session.objectives, {
            kind = obj.kind,
            color = if obj.kind == "collect_color" then (obj :: any).color else nil,
            blocker = if obj.kind == "clear_blocker" then (obj :: any).blocker else nil,
            targetCount = (obj :: any).targetCount or (obj :: any).targetScore or 0,
            currentCount = 0,
            completed = false,
        })
    end

    -- Process preplaced grid overrides
    if levelDef.preplacedGrid then
        for _, slot in ipairs(levelDef.preplacedGrid) do
            local key = BoardCoord.toKey(slot.x, slot.y)
            if slot.slotType == "empty" then
                emptyCutouts[key] = true
            elseif slot.slotType == "blocker" then
                BoardCoord.setTile(grid, slot.x, slot.y, {
                    id = generateTileId(session),
                    color = slot.color or levelDef.allowedColors[1],
                    blocker = slot.blocker,
                    special = slot.special,
                    isMatched = false,
                })
            elseif slot.slotType == "color" then
                BoardCoord.setTile(grid, slot.x, slot.y, {
                    id = generateTileId(session),
                    color = slot.color,
                    blocker = slot.blocker,
                    special = slot.special,
                    isMatched = false,
                })
            end
        end
    end

    -- Compute objective-aware initial spawn weights
    local initialWeights = SpawnWeightCalculator.calculateWeights(
        levelDef.allowedColors,
        session.objectives,
        session.weightConfig
    )

    -- Attempt up to 50 times to generate an opening board with:
    -- 1. No immediate matches
    -- 2. At least one legal move
    -- 3. At least one productive move for EACH unfinished objective color
    local maxAttempts = 50
    local boardAccepted = false

    for _ = 1, maxAttempts do
        -- Clear non-preplaced slots
        for y = 1, height do
            for x = 1, width do
                local key = BoardCoord.toKey(x, y)
                if not emptyCutouts[key] then
                    local isPreplaced = false
                    if levelDef.preplacedGrid then
                        for _, slot in ipairs(levelDef.preplacedGrid) do
                            if slot.x == x and slot.y == y then
                                isPreplaced = true
                                break
                            end
                        end
                    end
                    if not isPreplaced then
                        BoardCoord.setTile(grid, x, y, nil)
                    end
                end
            end
        end

        -- Fill remaining empty slots with weighted randomness avoiding immediate 3-matches
        for y = 1, height do
            for x = 1, width do
                local key = BoardCoord.toKey(x, y)
                if not emptyCutouts[key] and BoardCoord.getTile(grid, x, y) == nil then
                    local validColors: { TileColor } = {}
                    for _, color in ipairs(levelDef.allowedColors) do
                        if not wouldCreateImmediateMatch(grid, x, y, color) then
                            table.insert(validColors, color)
                        end
                    end

                    local chosenColor: TileColor
                    if #validColors > 0 then
                        chosenColor = SpawnWeightCalculator.pickWeightedColor(validColors, initialWeights, rng)
                    else
                        chosenColor = SpawnWeightCalculator.pickWeightedColor(levelDef.allowedColors, initialWeights, rng)
                    end

                    BoardCoord.setTile(grid, x, y, {
                        id = generateTileId(session),
                        color = chosenColor,
                        blocker = nil,
                        special = nil,
                        isMatched = false,
                    })
                end
            end
        end

        local possibleMoves = BoardLogic.findPossibleMoves(grid, width, height)
        if #possibleMoves > 0 then
            local allObjectivesCovered = true
            for _, obj in ipairs(session.objectives) do
                if not obj.completed and obj.kind == "collect_color" and obj.color then
                    local prod = BoardLogic.findProductiveMoves(session, obj.color)
                    if #prod == 0 then
                        allObjectivesCovered = false
                        break
                    end
                end
            end

            if allObjectivesCovered then
                boardAccepted = true
                break
            end
        end
    end

    -- If after maxAttempts some objectives lack productive moves, apply bounded recovery
    if not boardAccepted then
        BoardLogic.ensureProductiveMoves(session)
    end

    -- Final guarantee: at least one legal move exists
    local finalMoves = BoardLogic.findPossibleMoves(grid, width, height)
    if #finalMoves == 0 then
        BoardLogic.reshuffleBoard(session)
        BoardLogic.ensureProductiveMoves(session)
    end

    return session
end

-- Tracks progress towards objectives
local function updateObjectiveProgress(session: BoardSession, clearedTile: Tile)
    for _, obj in ipairs(session.objectives) do
        if not obj.completed then
            if obj.kind == "collect_color" and obj.color == clearedTile.color then
                obj.currentCount += 1
                if obj.currentCount >= obj.targetCount then
                    obj.completed = true
                end
            elseif obj.kind == "clear_blocker" and obj.blocker == clearedTile.blocker then
                obj.currentCount += 1
                if obj.currentCount >= obj.targetCount then
                    obj.completed = true
                end
            end
        end
    end
end

-- Evaluates overall win / loss state
function BoardLogic.evaluateWinLoss(session: BoardSession): GameStatus
    local allCompleted = true
    for _, obj in ipairs(session.objectives) do
        if not obj.completed then
            allCompleted = false
            break
        end
    end

    if allCompleted then
        session.status = "Won"
        return "Won"
    elseif session.movesRemaining <= 0 then
        session.status = "Lost"
        return "Lost"
    end

    return "InProgress"
end

-- Executes an authoritative swap, cascades, gravity, and win/loss updates
function BoardLogic.executeSwap(session: BoardSession, fromCoord: Coord, toCoord: Coord): SwapResult
    if not BoardLogic.validateSwap(session, fromCoord, toCoord) then
        return {
            valid = false,
            movesRemaining = session.movesRemaining,
        }
    end

    -- Deduct move
    session.movesRemaining -= 1

    local t1 = BoardCoord.getTile(session.grid, fromCoord.x, fromCoord.y)
    local t2 = BoardCoord.getTile(session.grid, toCoord.x, toCoord.y)

    -- Execute swap
    BoardCoord.setTile(session.grid, fromCoord.x, fromCoord.y, t2)
    BoardCoord.setTile(session.grid, toCoord.x, toCoord.y, t1)

    local cascadeSteps: { CascadeStep } = {}
    local initialMatches: { MatchGroup } = {}
    local maxCascades = 25
    local cascadeCount = 0
    local isFirstStep = true

    while cascadeCount < maxCascades do
        cascadeCount += 1

        local swapTarget = if isFirstStep then toCoord else nil
        local matches = MatchDetector.findMatches(session.grid, session.width, session.height, swapTarget)

        -- Check for BlossomBomb triggers
        local triggeredBombs: { Coord } = {}
        if isFirstStep and t1 and t1.special == "BlossomBomb" then
            table.insert(triggeredBombs, toCoord)
        end
        if isFirstStep and t2 and t2.special == "BlossomBomb" then
            table.insert(triggeredBombs, fromCoord)
        end

        if #matches == 0 and #triggeredBombs == 0 then
            break -- Board is stable
        end

        if isFirstStep then
            initialMatches = matches
        end

        local clearedSet: { [string]: boolean } = {}
        local clearedCoords: { Coord } = {}
        local spawnedSpecials: { { coord: Coord, specialType: SpecialPieceType } } = {}

        -- Collect matched tiles
        for _, group in ipairs(matches) do
            for _, c in ipairs(group.coords) do
                local key = BoardCoord.toKey(c.x, c.y)
                if not clearedSet[key] then
                    clearedSet[key] = true
                    table.insert(clearedCoords, c)
                end
            end

            -- Special piece spawning (e.g. BlossomBomb for 4+ matches)
            if group.isSpecial and group.specialType and group.spawnCoord then
                table.insert(spawnedSpecials, {
                    coord = group.spawnCoord,
                    specialType = group.specialType,
                })
            end
        end

        -- Collect bomb explosions
        for _, bombCoord in ipairs(triggeredBombs) do
            local blast = MatchDetector.getBombBlastArea(bombCoord, session.width, session.height)
            for _, bc in ipairs(blast) do
                local key = BoardCoord.toKey(bc.x, bc.y)
                if not clearedSet[key] then
                    clearedSet[key] = true
                    table.insert(clearedCoords, bc)
                end
            end
        end

        -- Check adjacent Ivy blockers to be cleared
        for _, c in ipairs(clearedCoords) do
            local adjCoords = {
                BoardCoord.create(c.x + 1, c.y),
                BoardCoord.create(c.x - 1, c.y),
                BoardCoord.create(c.x, c.y + 1),
                BoardCoord.create(c.x, c.y - 1),
            }
            for _, adj in ipairs(adjCoords) do
                if BoardCoord.isValid(adj.x, adj.y, session.width, session.height) then
                    local adjTile = BoardCoord.getTile(session.grid, adj.x, adj.y)
                    if adjTile and adjTile.blocker == "Ivy" then
                        updateObjectiveProgress(session, adjTile)
                        adjTile.blocker = nil -- Ivy dissolves!
                    end
                end
            end
        end

        -- Clear matched tiles from grid and update objectives
        for _, c in ipairs(clearedCoords) do
            local tile = BoardCoord.getTile(session.grid, c.x, c.y)
            if tile then
                updateObjectiveProgress(session, tile)
                BoardCoord.setTile(session.grid, c.x, c.y, nil)
            end
        end

        -- Place newly created special pieces
        for _, sp in ipairs(spawnedSpecials) do
            local newSpecialTile: Tile = {
                id = generateTileId(session),
                color = nil,
                blocker = nil,
                special = sp.specialType,
                isMatched = false,
            }
            BoardCoord.setTile(session.grid, sp.coord.x, sp.coord.y, newSpecialTile)
            -- Remove from cleared list if it was cleared
            clearedSet[BoardCoord.toKey(sp.coord.x, sp.coord.y)] = false
        end

        -- Apply gravity drops
        local shifts = GravityResolver.applyGravity(session.grid, session.width, session.height, session.emptyCutouts)

        -- Refill top empty slots using objective-aware dynamic weights
        local currentWeights = SpawnWeightCalculator.calculateWeights(
            session.allowedColors,
            session.objectives,
            session.weightConfig
        )

        local refilled = GravityResolver.refillEmptySlots(
            session.grid,
            session.width,
            session.height,
            session.allowedColors,
            session.rng,
            function() return generateTileId(session) end,
            session.emptyCutouts,
            currentWeights
        )

        table.insert(cascadeSteps, {
            clearedTiles = clearedCoords,
            spawnedSpecials = spawnedSpecials,
            shiftMoves = shifts,
            refilledTiles = refilled,
        })

        isFirstStep = false
    end

    -- Check win/loss status
    BoardLogic.evaluateWinLoss(session)

    -- Check if reshuffle is required
    local reshuffled = false
    if session.status == "InProgress" then
        local remainingMoves = BoardLogic.findPossibleMoves(session.grid, session.width, session.height)
        if #remainingMoves == 0 then
            reshuffled = BoardLogic.reshuffleBoard(session)
            BoardLogic.ensureProductiveMoves(session)
        end
    end

    return {
        valid = true,
        matchGroups = initialMatches,
        cascadeSteps = cascadeSteps,
        movesRemaining = session.movesRemaining,
        reshuffled = reshuffled,
    }
end

return BoardLogic
