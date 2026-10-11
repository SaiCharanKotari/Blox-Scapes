--!strict
-- WeightedRandomness.spec.luau: Comprehensive Unit Tests for Objective-Weighted Randomness and Board Fairness
-- Verifies mathematical distribution, deficit scaling, completed objective reallocation, productive move detection, and bounded recovery
-- Runs headlessly under Lune CLI and Roblox Studio

local BoardTypes = require("../src/shared/Types/BoardTypes")
local LevelTypes = require("../src/shared/Types/LevelTypes")
local BoardCoord = require("../src/shared/Utils/BoardCoord")
local MatchDetector = require("../src/shared/Puzzle/MatchDetector")
local GravityResolver = require("../src/shared/Puzzle/GravityResolver")
local BoardLogic = require("../src/shared/Puzzle/BoardLogic")
local SpawnWeightCalculator = require("../src/shared/Puzzle/SpawnWeightCalculator")

type Coord = BoardTypes.Coord
type Tile = BoardTypes.Tile
type Grid = BoardTypes.Grid
type TileColor = BoardTypes.TileColor
type ObjectiveState = BoardTypes.ObjectiveState
type LevelDefinition = LevelTypes.LevelDefinition

local function assertEqual<T>(actual: T, expected: T, message: string)
    if actual ~= expected then
        error(string.format("Assertion Failed: %s (Expected: %s, Got: %s)", message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(condition: boolean, message: string)
    if not condition then
        error(string.format("Assertion Failed: %s (Expected true, Got false)", message), 2)
    end
end

local function assertFalse(condition: boolean, message: string)
    if condition then
        error(string.format("Assertion Failed: %s (Expected false, Got true)", message), 2)
    end
end

local Tests = {}

-- TEST W01: WEIGHT CALCULATION WITH UNFINISHED OBJECTIVES
function Tests.TEST_W01_WEIGHT_CALCULATION_UNFINISHED()
    local allowedColors: { TileColor } = { "Berry", "Leaf", "Blossom", "Dewdrop" }
    local objectives: { ObjectiveState } = {
        { kind = "collect_color", color = "Leaf", targetCount = 8, currentCount = 0, completed = false },
        { kind = "collect_color", color = "Berry", targetCount = 6, currentCount = 0, completed = false },
    }
    local config = {
        baseWeight = 1.0,
        objectiveBoost = 0.5,
        deficitScale = 0.5,
        targetObjectiveRatio = 0.60,
    }

    local weights = SpawnWeightCalculator.calculateWeights(allowedColors, objectives, config)

    -- Leaf and Berry must be boosted over Blossom and Dewdrop
    assertTrue(weights["Leaf"] > weights["Blossom"], "Leaf weight must exceed Blossom weight")
    assertTrue(weights["Berry"] > weights["Blossom"], "Berry weight must exceed Blossom weight")
    assertEqual(weights["Blossom"], weights["Dewdrop"], "Non-objective colors must share equal baseline weight")

    -- Deficit scaling: Leaf deficit (8) > Berry deficit (6), so Leaf weight > Berry weight
    assertTrue(weights["Leaf"] > weights["Berry"], "Leaf (deficit 8) must have higher weight than Berry (deficit 6)")

    -- Combined target objective ratio must equal ~0.60
    local objectiveSum = weights["Leaf"] + weights["Berry"]
    assertTrue(math.abs(objectiveSum - 0.60) < 0.001, "Combined objective weights must match target ratio 0.60")

    -- Total weights must normalize strictly to 1.0
    local total = weights["Leaf"] + weights["Berry"] + weights["Blossom"] + weights["Dewdrop"]
    assertTrue(math.abs(total - 1.0) < 0.0001, "Total weights must sum to 1.0")
end

-- TEST W02: COMPLETED OBJECTIVES STOP RECEIVING BOOST
function Tests.TEST_W02_COMPLETED_OBJECTIVES_STOP_BOOST()
    local allowedColors: { TileColor } = { "Berry", "Leaf", "Blossom", "Dewdrop" }

    -- Step A: Berry is completed, only Leaf remains unfinished
    local objectivesPartiallyDone: { ObjectiveState } = {
        { kind = "collect_color", color = "Leaf", targetCount = 8, currentCount = 2, completed = false },
        { kind = "collect_color", color = "Berry", targetCount = 6, currentCount = 6, completed = true },
    }
    local weightsPartiallyDone = SpawnWeightCalculator.calculateWeights(allowedColors, objectivesPartiallyDone, {
        targetObjectiveRatio = 0.60,
    })

    -- Berry must drop back down to ordinary color baseline
    assertTrue(math.abs(weightsPartiallyDone["Berry"] - weightsPartiallyDone["Blossom"]) < 0.001,
        "Completed Berry must equal ordinary Blossom weight")
    assertEqual(weightsPartiallyDone["Blossom"], weightsPartiallyDone["Dewdrop"],
        "Blossom and Dewdrop must maintain equal baseline weight")
    assertTrue(weightsPartiallyDone["Leaf"] > weightsPartiallyDone["Berry"],
        "Remaining Leaf objective must still receive boosted probability")

    -- Step B: Both Leaf and Berry are completed
    local objectivesAllDone: { ObjectiveState } = {
        { kind = "collect_color", color = "Leaf", targetCount = 8, currentCount = 8, completed = true },
        { kind = "collect_color", color = "Berry", targetCount = 6, currentCount = 6, completed = true },
    }
    local weightsAllDone = SpawnWeightCalculator.calculateWeights(allowedColors, objectivesAllDone, {
        targetObjectiveRatio = 0.60,
    })

    -- When all objectives are completed, all colors must be exactly uniform (0.25 each)
    for _, color in ipairs(allowedColors) do
        assertTrue(math.abs(weightsAllDone[color] - 0.25) < 0.0001,
            string.format("%s must receive uniform 25%% weight when all objectives completed", color))
    end
end

-- TEST W03: STATISTICAL SPAWN DISTRIBUTION OVER LARGE SAMPLE
function Tests.TEST_W03_STATISTICAL_DISTRIBUTION_SAMPLE()
    local allowedColors: { TileColor } = { "Berry", "Leaf", "Blossom", "Dewdrop" }
    local objectives: { ObjectiveState } = {
        { kind = "collect_color", color = "Leaf", targetCount = 8, currentCount = 0, completed = false },
        { kind = "collect_color", color = "Berry", targetCount = 6, currentCount = 0, completed = false },
    }
    local config = {
        targetObjectiveRatio = 0.60,
        deficitScale = 0.5,
    }

    local expectedWeights = SpawnWeightCalculator.calculateWeights(allowedColors, objectives, config)
    local rng = BoardLogic.createRNG(987654321)

    local sampleCount = 10000
    local counts: { [TileColor]: number } = { Berry = 0, Leaf = 0, Blossom = 0, Dewdrop = 0 }

    for _ = 1, sampleCount do
        local color = SpawnWeightCalculator.pickWeightedColor(allowedColors, expectedWeights, rng)
        counts[color] += 1
    end

    for _, color in ipairs(allowedColors) do
        local observedFreq = counts[color] / sampleCount
        local expectedFreq = expectedWeights[color]
        local delta = math.abs(observedFreq - expectedFreq)
        -- Observed frequencies must be within 2.0% tolerance of calculated weights
        assertTrue(delta < 0.02, string.format("%s observed frequency %.3f deviated more than 2%% from expected %.3f (delta=%.3f)",
            color, observedFreq, expectedFreq, delta))
    end

    -- Confirmed: Leaf and Berry spawn significantly more than Blossom and Dewdrop
    assertTrue(counts["Leaf"] > counts["Blossom"], "Leaf sample count must be greater than Blossom")
    assertTrue(counts["Berry"] > counts["Dewdrop"], "Berry sample count must be greater than Dewdrop")
end

-- TEST W04: OPENING BOARD GUARANTEES PRODUCTIVE MOVES FOR ALL OBJECTIVES
function Tests.TEST_W04_OPENING_BOARD_PRODUCTIVE_MOVES()
    local levelDef: LevelDefinition = {
        id = 1,
        title = "First Blooms",
        width = 8,
        height = 8,
        moveLimit = 25,
        allowedColors = { "Berry", "Leaf", "Blossom", "Dewdrop" },
        objectives = {
            { kind = "collect_color", color = "Leaf", targetCount = 8 },
            { kind = "collect_color", color = "Berry", targetCount = 6 },
        },
        starThresholds = { 1000, 2000, 3000 },
        coinReward = 50,
        starReward = 1,
        objectiveWeightConfig = {
            targetObjectiveRatio = 0.60,
        },
    }

    -- Test 30 opening boards generated with distinct seeds
    for seed = 2001, 2030 do
        local session = BoardLogic.createSession(levelDef, seed)

        -- 1. Must have zero immediate pre-existing matches
        local matches = MatchDetector.findMatches(session.grid, session.width, session.height)
        assertEqual(#matches, 0, string.format("Seed %d opening board must have zero immediate matches", seed))

        -- 2. Must have at least one legal move
        local moves = BoardLogic.findPossibleMoves(session.grid, session.width, session.height)
        assertTrue(#moves >= 1, string.format("Seed %d opening board must have at least one legal move", seed))

        -- 3. Must have at least one productive move that collects Leaf
        local leafMoves = BoardLogic.findProductiveMoves(session, "Leaf")
        assertTrue(#leafMoves >= 1, string.format("Seed %d opening board must have at least one productive Leaf move", seed))

        -- 4. Must have at least one productive move that collects Berry
        local berryMoves = BoardLogic.findProductiveMoves(session, "Berry")
        assertTrue(#berryMoves >= 1, string.format("Seed %d opening board must have at least one productive Berry move", seed))
    end
end

-- TEST W05: PRODUCTIVE MOVE DEFINITION ACCURACY
function Tests.TEST_W05_PRODUCTIVE_MOVE_DEFINITION()
    local levelDef: LevelDefinition = {
        id = 1,
        title = "Productivity Test",
        width = 4,
        height = 4,
        moveLimit = 10,
        allowedColors = { "Berry", "Leaf", "Blossom", "Dewdrop" },
        objectives = {
            { kind = "collect_color", color = "Leaf", targetCount = 5 },
            { kind = "collect_color", color = "Berry", targetCount = 5 },
        },
        starThresholds = { 100, 200, 300 },
        coinReward = 50,
        starReward = 1,
    }

    local session = BoardLogic.createSession(levelDef, 12345)

    -- Explicitly lay out a 4x4 grid:
    -- Row 1: Leaf    Leaf    Blossom Dewdrop
    -- Row 2: Berry   Blossom Dewdrop Leaf
    -- Row 3: Dewdrop Dewdrop Blossom Dewdrop
    -- Row 4: Blossom Dewdrop Leaf    Leaf
    --
    -- At (3, 1), placing Blossom while (3, 2) is Leaf:
    -- Swapping (3, 1) Blossom with (3, 2) Leaf -> creates 3-Leaf match on Row 1!
    local colors: { { TileColor } } = {
        { "Leaf", "Leaf", "Blossom", "Berry" },
        { "Berry", "Blossom", "Leaf", "Dewdrop" },
        { "Dewdrop", "Blossom", "Berry", "Leaf" },
        { "Blossom", "Dewdrop", "Berry", "Dewdrop" },
    }

    for y = 1, 4 do
        for x = 1, 4 do
            BoardCoord.setTile(session.grid, x, y, {
                id = string.format("tile_%d_%d", x, y),
                color = colors[y][x],
                blocker = nil,
                special = nil,
                isMatched = false,
            })
        end
    end

    -- Move 1: Swap (3, 1) and (3, 2). Leaf moves to (3, 1) forming Row 1: Leaf, Leaf, Leaf!
    local cA = BoardCoord.create(3, 1)
    local cB = BoardCoord.create(3, 2)
    local prod1 = BoardLogic.analyzeMoveProductivity(session, cA, cB)

    assertTrue((prod1["Leaf"] or 0) >= 3, "Move must collect at least 3 Leaf tiles")
    assertEqual(prod1["Berry"] or 0, 0, "Move must collect 0 Berry tiles")
    assertTrue(BoardLogic.isMoveProductiveForColor(session, cA, cB, "Leaf"), "Move must be reported productive for Leaf")
    assertFalse(BoardLogic.isMoveProductiveForColor(session, cA, cB, "Berry"), "Move must NOT be reported productive for Berry")
    assertFalse(BoardLogic.isMoveProductiveForColor(session, cA, cB, "Dewdrop"), "Move must NOT be reported productive for Dewdrop")
end

-- TEST W06: CASCADE REFILL USES DYNAMIC WEIGHTS
function Tests.TEST_W06_CASCADE_REFILL_USES_WEIGHTS()
    local levelDef: LevelDefinition = {
        id = 1,
        title = "Refill Test",
        width = 8,
        height = 8,
        moveLimit = 25,
        allowedColors = { "Berry", "Leaf", "Blossom", "Dewdrop" },
        objectives = {
            { kind = "collect_color", color = "Leaf", targetCount = 8 },
            { kind = "collect_color", color = "Berry", targetCount = 6 },
        },
        starThresholds = { 1000, 2000, 3000 },
        coinReward = 50,
        starReward = 1,
        objectiveWeightConfig = {
            targetObjectiveRatio = 0.60,
        },
    }

    local session = BoardLogic.createSession(levelDef, 55555)
    local moves = BoardLogic.findProductiveMoves(session, "Leaf")
    assertTrue(#moves >= 1, "Must have productive Leaf move")

    -- Execute productive move
    local swapRes = BoardLogic.executeSwap(session, moves[1].from, moves[1].to)
    assertTrue(swapRes.valid, "Swap must be valid")
    assertTrue(swapRes.cascadeSteps ~= nil and #swapRes.cascadeSteps > 0, "Must have cascade steps")

    -- Verify all refilled tiles have valid IDs and allowed colors
    for _, step in ipairs(swapRes.cascadeSteps) do
        for _, refill in ipairs(step.refilledTiles) do
            assertTrue(refill.tile.color ~= nil, "Refilled tile must have color")
            assertTrue(table.find(levelDef.allowedColors, refill.tile.color) ~= nil, "Color must be an allowed color")
            assertTrue(BoardCoord.isValid(refill.coord.x, refill.coord.y, session.width, session.height), "Refill coord must be valid")
        end
    end
end

-- TEST W07: BOUNDED RECOVERY PRESERVES BLOCKERS AND SPECIALS
function Tests.TEST_W07_BOUNDED_RECOVERY_PRESERVES_BLOCKERS()
    local levelDef: LevelDefinition = {
        id = 2,
        title = "Blocker Test",
        width = 8,
        height = 8,
        moveLimit = 20,
        allowedColors = { "Berry", "Leaf", "Blossom", "Dewdrop" },
        objectives = {
            { kind = "collect_color", color = "Leaf", targetCount = 8 },
        },
        starThresholds = { 1000, 2000, 3000 },
        preplacedGrid = {
            { x = 1, y = 1, slotType = "blocker", blocker = "Stone", color = nil },
            { x = 2, y = 1, slotType = "blocker", blocker = "Ivy", color = "Berry" },
            { x = 8, y = 8, slotType = "color", special = "BlossomBomb", color = nil },
        },
        coinReward = 50,
        starReward = 1,
    }

    local session = BoardLogic.createSession(levelDef, 77777)
    BoardLogic.ensureProductiveMoves(session)

    -- Verify preplaced Stone, Ivy, and BlossomBomb were strictly preserved
    local tStone = BoardCoord.getTile(session.grid, 1, 1)
    local tIvy = BoardCoord.getTile(session.grid, 2, 1)
    local tBomb = BoardCoord.getTile(session.grid, 8, 8)

    assertTrue(tStone ~= nil and tStone.blocker == "Stone", "Stone blocker at (1,1) must be preserved")
    assertTrue(tIvy ~= nil and tIvy.blocker == "Ivy", "Ivy blocker at (2,1) must be preserved")
    assertTrue(tBomb ~= nil and tBomb.special == "BlossomBomb", "BlossomBomb at (8,8) must be preserved")
    assertEqual(session.width, 8, "Width must remain 8")
    assertEqual(session.height, 8, "Height must remain 8")
end

function Tests.runAll(): { total: number, passed: number, failed: number }
    local total = 0
    local passed = 0
    local failed = 0

    print("=================================================================")
    print("  BLOOMTRAIL WEIGHTED RANDOMNESS & FAIRNESS SUITE (Pure Luau)")
    print("=================================================================")

    local testNames: { string } = {}
    for name in pairs(Tests) do
        if string.sub(name, 1, 5) == "TEST_" then
            table.insert(testNames, name)
        end
    end
    table.sort(testNames)

    for _, name in ipairs(testNames) do
        total += 1
        local fn = Tests[name]
        local success, err = pcall(fn)
        if success then
            passed += 1
            print(string.format("  [PASS] %s", name))
        else
            failed += 1
            print(string.format("  [FAIL] %s: %s", name, tostring(err)))
        end
    end

    print("=================================================================")
    print(string.format("  TOTAL: %d | PASSED: %d | FAILED: %d", total, passed, failed))
    print("=================================================================")

    return { total = total, passed = passed, failed = failed }
end

return Tests
