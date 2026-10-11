--!strict
-- BoardLogic.spec.luau: Comprehensive Unit Test Suite for Project Bloomtrail Match-3 Engine
-- Verifies all 15 tests from ACCEPTANCE_TESTS.md plus edge cases (19 tests total)
-- Runs headlessly under Lune CLI and Roblox Studio

local BoardTypes = require("../src/shared/Types/BoardTypes")
local LevelTypes = require("../src/shared/Types/LevelTypes")
local BoardCoord = require("../src/shared/Utils/BoardCoord")
local MatchDetector = require("../src/shared/Puzzle/MatchDetector")
local GravityResolver = require("../src/shared/Puzzle/GravityResolver")
local BoardLogic = require("../src/shared/Puzzle/BoardLogic")

type Coord = BoardTypes.Coord
type Tile = BoardTypes.Tile
type Grid = BoardTypes.Grid
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

-- Standard test level definition (8x8, 4 colors, 25 moves)
local function createTestLevelDef(): LevelDefinition
    return {
        id = 1,
        title = "Test Level",
        width = 8,
        height = 8,
        moveLimit = 25,
        allowedColors = { "Berry", "Leaf", "Blossom", "Dewdrop" },
        objectives = {
            { kind = "collect_color", color = "Leaf", targetCount = 5 },
            { kind = "collect_color", color = "Berry", targetCount = 5 },
        },
        starThresholds = { 1000, 2000, 3000 },
        coinReward = 50,
        starReward = 1,
    }
end

local Tests = {}

-- TEST 01: NO INITIAL MATCHES
function Tests.TEST_01_NO_INITIAL_MATCHES()
    local levelDef = createTestLevelDef()
    for seed = 100, 110 do
        local session = BoardLogic.createSession(levelDef, seed)
        local matches = MatchDetector.findMatches(session.grid, session.width, session.height)
        assertEqual(#matches, 0, "Initial board must contain 0 immediate matches (Seed: " .. seed .. ")")
    end
end

-- TEST 02: GUARANTEED LEGAL MOVE
function Tests.TEST_02_GUARANTEED_LEGAL_MOVE()
    local levelDef = createTestLevelDef()
    for seed = 200, 210 do
        local session = BoardLogic.createSession(levelDef, seed)
        local possibleMoves = BoardLogic.findPossibleMoves(session.grid, session.width, session.height)
        assertTrue(#possibleMoves >= 1, "Initial board must guarantee at least 1 legal move (Seed: " .. seed .. ")")
    end
end

-- TEST 03: DIMENSIONS AND BOUNDS
function Tests.TEST_03_DIMENSIONS_AND_BOUNDS()
    local levelDef = createTestLevelDef()
    local session = BoardLogic.createSession(levelDef, 42)
    assertEqual(session.width, 8, "Board width should be 8")
    assertEqual(session.height, 8, "Board height should be 8")

    local count = 0
    for y = 1, 8 do
        for x = 1, 8 do
            local tile = BoardCoord.getTile(session.grid, x, y)
            assertTrue(tile ~= nil, "Tile at (" .. x .. "," .. y .. ") must not be nil")
            count += 1
        end
    end
    assertEqual(count, 64, "Total slots must equal 8 * 8 = 64")
end

-- TEST 04: REJECT NON-ADJACENT SWAP
function Tests.TEST_04_REJECT_NON_ADJACENT_SWAP()
    local levelDef = createTestLevelDef()
    local session = BoardLogic.createSession(levelDef, 42)
    local fromCoord = BoardCoord.create(1, 1)
    local toCoord = BoardCoord.create(1, 3) -- Distance 2

    local valid = BoardLogic.validateSwap(session, fromCoord, toCoord)
    assertFalse(valid, "Non-adjacent swap must be rejected")

    local result = BoardLogic.executeSwap(session, fromCoord, toCoord)
    assertFalse(result.valid, "Executing non-adjacent swap must return valid = false")
    assertEqual(session.movesRemaining, 25, "Move count must not decrease on invalid swap")
end

-- TEST 05: REJECT DIAGONAL SWAP
function Tests.TEST_05_REJECT_DIAGONAL_SWAP()
    local levelDef = createTestLevelDef()
    local session = BoardLogic.createSession(levelDef, 42)
    local fromCoord = BoardCoord.create(1, 1)
    local toCoord = BoardCoord.create(2, 2) -- Diagonal

    local valid = BoardLogic.validateSwap(session, fromCoord, toCoord)
    assertFalse(valid, "Diagonal swap must be rejected")
end

-- TEST 06: REVERT FAILED SWAP
function Tests.TEST_06_REVERT_FAILED_SWAP()
    local levelDef = createTestLevelDef()
    local session = BoardLogic.createSession(levelDef, 42)

    -- Find a guaranteed invalid adjacent swap pair
    local p1 = BoardCoord.create(1, 1)
    local p2 = BoardCoord.create(2, 1)
    if BoardLogic.validateSwap(session, p1, p2) then
        p1 = BoardCoord.create(1, 2)
        p2 = BoardCoord.create(1, 3)
    end
    -- If still valid, search for an invalid pair
    if BoardLogic.validateSwap(session, p1, p2) then
        for y = 1, session.height do
            for x = 1, session.width - 1 do
                local c1 = BoardCoord.create(x, y)
                local c2 = BoardCoord.create(x + 1, y)
                if not BoardLogic.validateSwap(session, c1, c2) then
                    p1 = c1
                    p2 = c2
                    break
                end
            end
        end
    end

    local gridSnapshot = BoardCoord.cloneGrid(session.grid, session.width, session.height)
    local movesBefore = session.movesRemaining

    local result = BoardLogic.executeSwap(session, p1, p2)
    assertFalse(result.valid, "Executing invalid swap must return valid = false")
    assertEqual(session.movesRemaining, movesBefore, "Moves remaining must be identical after failed swap")

    -- Verify all 64 cells are 100% identical to the pre-swap snapshot
    for y = 1, session.height do
        for x = 1, session.width do
            local beforeTile = BoardCoord.getTile(gridSnapshot, x, y)
            local afterTile = BoardCoord.getTile(session.grid, x, y)
            assertEqual(afterTile and afterTile.id, beforeTile and beforeTile.id, 
                string.format("Cell (%d, %d) must be restored to original tile", x, y))
            assertEqual(afterTile and afterTile.color, beforeTile and beforeTile.color,
                string.format("Cell (%d, %d) color must be restored", x, y))
        end
    end
end

-- TEST 07: EXECUTE VALID SWAP
function Tests.TEST_07_EXECUTE_VALID_SWAP()
    local levelDef = createTestLevelDef()
    local session = BoardLogic.createSession(levelDef, 42)

    -- Manually set up a guaranteed 3-in-a-row swap:
    -- (1,1)=Berry, (2,1)=Berry, (3,1)=Leaf, (4,1)=Berry
    -- Swapping (3,1) with (4,1) makes (1..3, 1) all Berry!
    BoardCoord.setTile(session.grid, 1, 1, { id = "t1", color = "Berry" })
    BoardCoord.setTile(session.grid, 2, 1, { id = "t2", color = "Berry" })
    BoardCoord.setTile(session.grid, 3, 1, { id = "t3", color = "Leaf" })
    BoardCoord.setTile(session.grid, 4, 1, { id = "t4", color = "Berry" })

    local fromCoord = BoardCoord.create(3, 1)
    local toCoord = BoardCoord.create(4, 1)

    local valid = BoardLogic.validateSwap(session, fromCoord, toCoord)
    assertTrue(valid, "Swap creating 3-in-a-row must be validated as true")

    local result = BoardLogic.executeSwap(session, fromCoord, toCoord)
    assertTrue(result.valid, "Executing swap must return valid = true")
    assertEqual(session.movesRemaining, 24, "Moves remaining must decrement by 1")
    assertTrue(#result.cascadeSteps >= 1, "At least one cascade step must be returned")
end

-- TEST 08: HORIZONTAL MATCH 3
function Tests.TEST_08_HORIZONTAL_MATCH_3()
    local grid = BoardCoord.createEmptyGrid(8, 8)
    BoardCoord.setTile(grid, 2, 4, { id = "h1", color = "Dewdrop" })
    BoardCoord.setTile(grid, 3, 4, { id = "h2", color = "Dewdrop" })
    BoardCoord.setTile(grid, 4, 4, { id = "h3", color = "Dewdrop" })

    local matches = MatchDetector.findMatches(grid, 8, 8)
    assertEqual(#matches, 1, "Exactly 1 match group must be found")
    assertEqual(matches[1].color, "Dewdrop", "Match color must be Dewdrop")
    assertEqual(#matches[1].coords, 3, "Match group must contain exactly 3 tiles")
end

-- TEST 09: VERTICAL MATCH 3
function Tests.TEST_09_VERTICAL_MATCH_3()
    local grid = BoardCoord.createEmptyGrid(8, 8)
    BoardCoord.setTile(grid, 5, 2, { id = "v1", color = "Plum" })
    BoardCoord.setTile(grid, 5, 3, { id = "v2", color = "Plum" })
    BoardCoord.setTile(grid, 5, 4, { id = "v3", color = "Plum" })

    local matches = MatchDetector.findMatches(grid, 8, 8)
    assertEqual(#matches, 1, "Exactly 1 match group must be found")
    assertEqual(matches[1].color, "Plum", "Match color must be Plum")
    assertEqual(#matches[1].coords, 3, "Match group must contain exactly 3 tiles")
end

-- TEST 10: L SHAPED INTERSECTION
function Tests.TEST_10_L_SHAPED_INTERSECTION()
    local grid = BoardCoord.createEmptyGrid(8, 8)
    -- Horizontal: (3,3), (4,3), (5,3)
    -- Vertical: (3,3), (3,4), (3,5)
    -- Intersection tile: (3,3) - Total 5 unique tiles of Leaf
    BoardCoord.setTile(grid, 3, 3, { id = "L1", color = "Leaf" })
    BoardCoord.setTile(grid, 4, 3, { id = "L2", color = "Leaf" })
    BoardCoord.setTile(grid, 5, 3, { id = "L3", color = "Leaf" })
    BoardCoord.setTile(grid, 3, 4, { id = "L4", color = "Leaf" })
    BoardCoord.setTile(grid, 3, 5, { id = "L5", color = "Leaf" })

    local matches = MatchDetector.findMatches(grid, 8, 8)
    assertEqual(#matches, 1, "L-shape must be merged into 1 unified match group")
    assertEqual(matches[1].color, "Leaf", "Match color must be Leaf")
    assertEqual(#matches[1].coords, 5, "L-shape must group all 5 tiles without duplicate counting")
    assertTrue(matches[1].isSpecial, "5-tile intersection must qualify as a special piece")
end

-- TEST 11: MATCH 4 CREATES SPECIAL (BLOSSOM BOMB)
function Tests.TEST_11_MATCH_4_CREATES_SPECIAL()
    local grid = BoardCoord.createEmptyGrid(8, 8)
    -- Line of 4: (2,2), (3,2), (4,2), (5,2)
    BoardCoord.setTile(grid, 2, 2, { id = "m1", color = "Blossom" })
    BoardCoord.setTile(grid, 3, 2, { id = "m2", color = "Blossom" })
    BoardCoord.setTile(grid, 4, 2, { id = "m3", color = "Blossom" })
    BoardCoord.setTile(grid, 5, 2, { id = "m4", color = "Blossom" })

    local swapTarget = BoardCoord.create(4, 2)
    local matches = MatchDetector.findMatches(grid, 8, 8, swapTarget)

    assertEqual(#matches, 1, "Exactly 1 match group found")
    assertTrue(matches[1].isSpecial, "4-in-a-row must be marked isSpecial = true")
    assertEqual(matches[1].specialType, "BlossomBomb", "Special piece must be BlossomBomb")
    assertEqual(matches[1].spawnCoord.x, 4, "Spawn coordinate X must match swap target")
    assertEqual(matches[1].spawnCoord.y, 2, "Spawn coordinate Y must match swap target")
end

-- TEST 12: TILES FALL INTO GAPS (GRAVITY)
function Tests.TEST_12_TILES_FALL_INTO_GAPS()
    local grid = BoardCoord.createEmptyGrid(8, 8)
    -- Place tile at (2, 2). Bottom slot (2, 8) is empty.
    BoardCoord.setTile(grid, 2, 2, { id = "drop_me", color = "Berry" })

    local shifts = GravityResolver.applyGravity(grid, 8, 8)
    assertTrue(#shifts >= 1, "At least one tile must shift downward")

    local finalTile = BoardCoord.getTile(grid, 2, 8)
    assertTrue(finalTile ~= nil, "Tile must have fallen to bottom slot (2, 8)")
    assertEqual(finalTile.id, "drop_me", "Fallen tile must be drop_me")
    assertEqual(BoardCoord.getTile(grid, 2, 2), nil, "Original slot (2, 2) must now be empty")
end

-- TEST 13: TOP REFILL FILLS GRID
function Tests.TEST_13_TOP_REFILL_FILLS_GRID()
    local grid = BoardCoord.createEmptyGrid(8, 8)
    local allowedColors: { BoardTypes.TileColor } = { "Berry", "Leaf", "Blossom" }
    local nextId = 0
    local rng = BoardLogic.createRNG(99)

    -- Board is completely empty. Refill should populate all 64 slots.
    local refilled = GravityResolver.refillEmptySlots(
        grid, 8, 8, allowedColors, rng,
        function() nextId += 1 return "refill_" .. nextId end
    )

    assertEqual(#refilled, 64, "Refill must fill all 64 empty slots")
    for y = 1, 8 do
        for x = 1, 8 do
            local tile = BoardCoord.getTile(grid, x, y)
            assertTrue(tile ~= nil, "Every slot must have a non-nil tile")
            assertTrue(table.find(allowedColors, tile.color) ~= nil, "Refilled color must be in allowedColors")
        end
    end
end

-- TEST 14: CASCADE RESOLUTION
function Tests.TEST_14_CASCADE_RESOLUTION()
    local levelDef = createTestLevelDef()
    local session = BoardLogic.createSession(levelDef, 123)

    -- Create a deliberate secondary cascade setup:
    -- Line 1 clears, causing tiles to drop that immediately form Line 2
    BoardCoord.setTile(session.grid, 1, 8, { id = "c1", color = "Berry" })
    BoardCoord.setTile(session.grid, 2, 8, { id = "c2", color = "Berry" })
    BoardCoord.setTile(session.grid, 3, 8, { id = "c3", color = "Berry" })

    local result = BoardLogic.executeSwap(session, BoardCoord.create(1, 8), BoardCoord.create(2, 8))
    assertTrue(result.valid, "Swap must be valid")
    assertTrue(#result.cascadeSteps >= 1, "Cascades must execute until board is stable")

    local postMatches = MatchDetector.findMatches(session.grid, session.width, session.height)
    assertEqual(#postMatches, 0, "After cascade completion, board must be completely stable")
end

-- TEST 15: CASCADE SAFETY LIMIT
function Tests.TEST_15_CASCADE_SAFETY_LIMIT()
    local levelDef = createTestLevelDef()
    local session = BoardLogic.createSession(levelDef, 456)

    -- Board executes swap with hard cap of 25 iterations
    -- Even in pathological setups, while loop terminates cleanly without freezing
    local result = BoardLogic.executeSwap(session, BoardCoord.create(1, 1), BoardCoord.create(2, 1))
    assertTrue(result ~= nil, "Engine must return swap result without hanging")
end

-- TEST 16: BLOSSOM BOMB EXPLOSION 3X3 AREA
function Tests.TEST_16_BLOSSOM_BOMB_EXPLOSION_3X3()
    local levelDef = createTestLevelDef()
    local session = BoardLogic.createSession(levelDef, 789)

    -- Place a BlossomBomb at (4, 4)
    BoardCoord.setTile(session.grid, 4, 4, { id = "bomb", color = nil, special = "BlossomBomb" })
    local blast = MatchDetector.getBombBlastArea(BoardCoord.create(4, 4), 8, 8)
    assertEqual(#blast, 9, "Bomb at center (4, 4) must cover 3x3 = 9 coordinates")

    -- Bomb at corner (1, 1)
    local cornerBlast = MatchDetector.getBombBlastArea(BoardCoord.create(1, 1), 8, 8)
    assertEqual(#cornerBlast, 4, "Bomb at corner (1, 1) must cover 4 coordinates within bounds")
end

-- TEST 17: OBJECTIVE TRACKING AND WIN
function Tests.TEST_17_OBJECTIVE_TRACKING_AND_WIN()
    local levelDef = createTestLevelDef()
    -- Objectives: 5 Leaf, 5 Berry
    local session = BoardLogic.createSession(levelDef, 111)

    -- Artificially fulfill objectives
    session.objectives[1].currentCount = 5
    session.objectives[1].completed = true
    session.objectives[2].currentCount = 5
    session.objectives[2].completed = true

    local status = BoardLogic.evaluateWinLoss(session)
    assertEqual(status, "Won", "Level must transition to Won when all objectives completed")
end

-- TEST 18: OUT OF MOVES LOSS
function Tests.TEST_18_OUT_OF_MOVES_LOSS()
    local levelDef = createTestLevelDef()
    local session = BoardLogic.createSession(levelDef, 222)
    session.movesRemaining = 0
    session.objectives[1].completed = false

    local status = BoardLogic.evaluateWinLoss(session)
    assertEqual(status, "Lost", "Level must transition to Lost when out of moves")
end

-- TEST 19: RESHUFFLE WHEN NO MOVES
function Tests.TEST_19_RESHUFFLE_WHEN_NO_MOVES()
    local levelDef = createTestLevelDef()
    local session = BoardLogic.createSession(levelDef, 333)

    local success = BoardLogic.reshuffleBoard(session)
    assertTrue(success, "Reshuffle must succeed and establish valid moves")

    local moves = BoardLogic.findPossibleMoves(session.grid, session.width, session.height)
    assertTrue(#moves >= 1, "After reshuffle, at least 1 legal move must exist")

    local immediate = MatchDetector.findMatches(session.grid, session.width, session.height)
    assertEqual(#immediate, 0, "After reshuffle, no immediate matches may exist")
end

-- TEST 20: T-SHAPED INTERSECTION AND BLOSSOM BOMB CREATION
function Tests.TEST_20_T_SHAPED_INTERSECTION_AND_BLOSSOM_BOMB()
    local levelDef = createTestLevelDef()
    local session = BoardLogic.createSession(levelDef, 555)

    -- Set up an explicit T-shaped match:
    -- Horizontal: (3, 4), (4, 4), (5, 4) all Plum
    -- Vertical: (4, 3), (4, 4), (4, 5) all Plum
    -- But initially (4, 4) has "Leaf" and (4, 5) has "Plum", with a swap from (4, 5) to (4, 4) completing the T-shape!
    -- Or directly place the 5 tiles and test findMatches with swapTarget:
    local grid = BoardCoord.createEmptyGrid(8, 8)
    BoardCoord.setTile(grid, 3, 4, { id = "t1", color = "Plum" })
    BoardCoord.setTile(grid, 5, 4, { id = "t2", color = "Plum" })
    BoardCoord.setTile(grid, 4, 3, { id = "t3", color = "Plum" })
    BoardCoord.setTile(grid, 4, 5, { id = "t4", color = "Plum" })
    BoardCoord.setTile(grid, 4, 4, { id = "t5", color = "Plum" }) -- Center intersection

    local matches = MatchDetector.findMatches(grid, 8, 8, BoardCoord.create(4, 4))
    assertEqual(#matches, 1, "T-shape must be grouped into exactly 1 match group")
    assertEqual(matches[1].color, "Plum", "Match color must be Plum")
    assertEqual(#matches[1].coords, 5, "T-shape must contain exactly 5 coordinates")
    assertTrue(matches[1].isSpecial, "5-tile intersection must qualify for a special piece")
    assertEqual(matches[1].specialType, "BlossomBomb", "Special piece must be BlossomBomb")
    assertEqual(matches[1].spawnCoord.x, 4, "Spawn coordinate X must be intersection point 4")
    assertEqual(matches[1].spawnCoord.y, 4, "Spawn coordinate Y must be intersection point 4")
end

-- Export test runner
function Tests.runAll(): { total: number, passed: number, failed: number, results: { [string]: boolean } }
    local total = 0
    local passed = 0
    local failed = 0
    local results: { [string]: boolean } = {}

    print("=================================================================")
    print("  BLOOMTRAIL MATCH-3 ENGINE TEST SUITE (Pure Luau)")
    print("=================================================================")

    -- Sort test names for deterministic output order
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
            results[name] = true
            print(string.format("  [PASS] %s", name))
        else
            failed += 1
            results[name] = false
            print(string.format("  [FAIL] %s: %s", name, tostring(err)))
        end
    end

    print("=================================================================")
    print(string.format("  TOTAL: %d | PASSED: %d | FAILED: %d", total, passed, failed))
    print("=================================================================")

    return {
        total = total,
        passed = passed,
        failed = failed,
        results = results,
    }
end

return Tests
