--!strict
-- simulate_level1.luau: Monte Carlo Simulation of Level 1 Across 500 Fixed Seeds
-- Evaluates objective-weighted randomness, goal-first policy completion rate, and move efficiency
-- Runs under Lune CLI

local LevelRegistry = require("../src/shared/Config/LevelRegistry")
local BoardLogic = require("../src/shared/Puzzle/BoardLogic")
local BoardCoord = require("../src/shared/Utils/BoardCoord")
local BoardTypes = require("../src/shared/Types/BoardTypes")

type TileColor = BoardTypes.TileColor
type Coord = BoardTypes.Coord

local levelDef = LevelRegistry.getLevel(1)
if not levelDef then
    error("Level 1 definition not found in LevelRegistry")
end

local NUM_SEEDS = 500
local wins = 0
local losses = 0
local totalMovesRemainingOnWin = 0
local minMovesRemaining = 999
local maxMovesRemaining = -1
local failedSeeds: { number } = {}

local totalSpawned: { [TileColor]: number } = {
    Leaf = 0,
    Berry = 0,
    Blossom = 0,
    Dewdrop = 0,
}
local totalTilesSpawnedCount = 0
local totalMovesPlayed = 0
local movesWithoutProductiveMove = 0

-- Goal-First Move Policy:
-- Evaluates all available legal moves and ranks them by direct objective contribution
local function selectBestMove(session: BoardLogic.BoardSession): (Coord?, Coord?, boolean)
    local moves = BoardLogic.findPossibleMoves(session.grid, session.width, session.height)
    if #moves == 0 then
        return nil, nil, false
    end

    local leafObj = session.objectives[1]
    local berryObj = session.objectives[2]

    local leafDeficit = if leafObj and not leafObj.completed then math.max(0, leafObj.targetCount - leafObj.currentCount) else 0
    local berryDeficit = if berryObj and not berryObj.completed then math.max(0, berryObj.targetCount - berryObj.currentCount) else 0

    local bestScore = -1
    local bestMove = moves[1]
    local isProductive = false

    for _, move in ipairs(moves) do
        local productivity = BoardLogic.analyzeMoveProductivity(session, move.from, move.to)
        local leafCount = productivity["Leaf"] or 0
        local berryCount = productivity["Berry"] or 0

        local score = 0
        if leafDeficit > 0 and leafCount > 0 then
            score += leafCount * 10 * (1 + leafDeficit / 8)
        end
        if berryDeficit > 0 and berryCount > 0 then
            score += berryCount * 10 * (1 + berryDeficit / 6)
        end

        local t1 = BoardCoord.getTile(session.grid, move.from.x, move.from.y)
        local t2 = BoardCoord.getTile(session.grid, move.to.x, move.to.y)
        if (t1 and t1.special == "BlossomBomb") or (t2 and t2.special == "BlossomBomb") then
            score += 15
        end

        if score > 0 then
            isProductive = true
        else
            -- Tie-breaker for non-productive moves: prefer matching other colors over random moves
            for color, count in pairs(productivity) do
                score += count
            end
        end

        if score > bestScore then
            bestScore = score
            bestMove = move
        end
    end

    return bestMove.from, bestMove.to, (bestScore > 0 and isProductive)
end

print("=================================================================")
print(string.format("  RUNNING BLOOMTRAIL LEVEL 1 SIMULATION (%d SEEDS)", NUM_SEEDS))
print(string.format("  Level: %s | Moves: %d | Goals: Leaf=%d, Berry=%d",
    levelDef.title, levelDef.moveLimit, levelDef.objectives[1].targetCount, levelDef.objectives[2].targetCount))
print("  Policy: Documented Simple Goal-First Selection")
print("=================================================================")

for seed = 1, NUM_SEEDS do
    local session = BoardLogic.createSession(levelDef, seed)

    -- Count opening board tiles
    for y = 1, session.height do
        for x = 1, session.width do
            local tile = BoardCoord.getTile(session.grid, x, y)
            if tile and tile.color and totalSpawned[tile.color] ~= nil then
                totalSpawned[tile.color] += 1
                totalTilesSpawnedCount += 1
            end
        end
    end

    while session.status == "InProgress" and session.movesRemaining > 0 do
        local fromCoord, toCoord, isProductive = selectBestMove(session)
        if not fromCoord or not toCoord then
            break
        end

        totalMovesPlayed += 1
        if not isProductive then
            movesWithoutProductiveMove += 1
        end

        local result = BoardLogic.executeSwap(session, fromCoord, toCoord)
        if not result.valid then
            break
        end

        -- Tally refill tiles spawned during cascades
        if result.cascadeSteps then
            for _, step in ipairs(result.cascadeSteps) do
                for _, refill in ipairs(step.refilledTiles) do
                    if refill.tile.color and totalSpawned[refill.tile.color] ~= nil then
                        totalSpawned[refill.tile.color] += 1
                        totalTilesSpawnedCount += 1
                    end
                end
            end
        end
    end

    if session.status == "Won" then
        wins += 1
        totalMovesRemainingOnWin += session.movesRemaining
        if session.movesRemaining < minMovesRemaining then
            minMovesRemaining = session.movesRemaining
        end
        if session.movesRemaining > maxMovesRemaining then
            maxMovesRemaining = session.movesRemaining
        end
    else
        losses += 1
        table.insert(failedSeeds, seed)
    end
end

local winRate = (wins / NUM_SEEDS) * 100
local avgMovesRemaining = if wins > 0 then (totalMovesRemainingOnWin / wins) else 0

print("\n=================================================================")
print("  SIMULATION RESULTS & EVIDENCE REPORT")
print("=================================================================")
print(string.format("  Total Runs           : %d", NUM_SEEDS))
print(string.format("  Victories            : %d (%.1f%%)", wins, winRate))
print(string.format("  Defeats              : %d (%.1f%%)", losses, (losses / NUM_SEEDS) * 100))
print(string.format("  Avg Moves Remaining  : %.2f moves (out of 25)", avgMovesRemaining))
print(string.format("  Min Moves Remaining  : %d moves", minMovesRemaining == 999 and 0 or minMovesRemaining))
print(string.format("  Max Moves Remaining  : %d moves", maxMovesRemaining))
print(string.format("  Total Moves Evaluated: %d", totalMovesPlayed))
print(string.format("  Moves w/o Goal Match : %d (%.1f%% of all player moves)",
    movesWithoutProductiveMove, (movesWithoutProductiveMove / totalMovesPlayed) * 100))

print("\n--- MEASURED TILE SPAWN FREQUENCIES ---")
for _, color in ipairs(levelDef.allowedColors) do
    local count = totalSpawned[color] or 0
    local pct = (count / totalTilesSpawnedCount) * 100
    print(string.format("  %-10s: %6d tiles (%.2f%%)", color, count, pct))
end

if #failedSeeds > 0 then
    print("\n--- FAILURE SEEDS ---")
    local seedList = {}
    for i = 1, math.min(#failedSeeds, 20) do
        table.insert(seedList, tostring(failedSeeds[i]))
    end
    print("  Seeds: " .. table.concat(seedList, ", ") .. (if #failedSeeds > 20 then "..." else ""))
else
    print("\n--- ZERO FAILURE SEEDS ACROSS ALL 500 RUNS ---")
end
print("=================================================================")
