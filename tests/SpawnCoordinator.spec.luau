--!strict
-- SpawnCoordinator.spec.luau: Unit Tests for 12-Player Spawn Allocation and Collision Prevention
-- Validates unique pad assignments, full capacity fallback, and disconnect cleanup

local SpawnCoordinator = require("../src/server/Services/SpawnCoordinator")

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

local Tests = {}

-- TEST S01: UNIQUE ALLOCATION FOR 12 PLAYERS
function Tests.TEST_S01_UNIQUE_ALLOCATION_FOR_12_PLAYERS()
    SpawnCoordinator._clearAllAssignments()

    local allocated = {}
    for i = 1, 12 do
        local mockPlayer = { Name = "Player_" .. i, UserId = 1000 + i }
        SpawnCoordinator.onPlayerAdded(mockPlayer)
        local assigned = SpawnCoordinator.getAssignedSpawn(mockPlayer)
        
        assertTrue(assigned ~= nil, "Assigned spawn index must not be nil")
        assertTrue(assigned >= 1 and assigned <= 12, "Assigned spawn index must be within 1..12")
        assertTrue(not allocated[assigned], string.format("Spawn index %d was assigned multiple times", assigned))
        allocated[assigned] = true
    end

    -- Verify all 12 unique pads were assigned
    for i = 1, 12 do
        assertTrue(allocated[i] == true, string.format("Spawn pad %d must be occupied", i))
    end
end

-- TEST S02: CAPACITY FALLBACK BEYOND 12 PLAYERS
function Tests.TEST_S02_CAPACITY_FALLBACK_BEYOND_12_PLAYERS()
    SpawnCoordinator._clearAllAssignments()

    for i = 1, 12 do
        local mockPlayer = { Name = "Player_" .. i, UserId = 1000 + i }
        SpawnCoordinator.onPlayerAdded(mockPlayer)
    end

    -- 13th player joins (server at capacity)
    local player13 = { Name = "Player_13", UserId = 1013 }
    SpawnCoordinator.onPlayerAdded(player13)
    local assigned13 = SpawnCoordinator.getAssignedSpawn(player13)

    assertTrue(assigned13 ~= nil, "13th player must receive a valid fallback spawn index")
    assertTrue(assigned13 >= 1 and assigned13 <= 12, "13th player spawn index must be within 1..12")
end

-- TEST S03: PLAYER DISCONNECT FREES PAD
function Tests.TEST_S03_PLAYER_DISCONNECT_FREES_PAD()
    SpawnCoordinator._clearAllAssignments()

    local p1 = { Name = "Player_1", UserId = 1001 }
    local p2 = { Name = "Player_2", UserId = 1002 }
    SpawnCoordinator.onPlayerAdded(p1)
    SpawnCoordinator.onPlayerAdded(p2)

    assertEqual(SpawnCoordinator.getAssignedSpawn(p1), 1, "Player 1 should be on pad 1")
    assertEqual(SpawnCoordinator.getAssignedSpawn(p2), 2, "Player 2 should be on pad 2")

    -- Player 1 leaves
    SpawnCoordinator.onPlayerRemoving(p1)
    assertEqual(SpawnCoordinator.getAssignedSpawn(p1), nil, "Player 1 assignment should be cleared")

    -- Player 3 joins and should reclaim pad 1
    local p3 = { Name = "Player_3", UserId = 1003 }
    SpawnCoordinator.onPlayerAdded(p3)
    assertEqual(SpawnCoordinator.getAssignedSpawn(p3), 1, "Player 3 should reclaim freed pad 1")
end

local function runAll(): { total: number, passed: number, failed: number }
    local total = 0
    local passed = 0
    local failed = 0

    print("=================================================================")
    print("  BLOOMTRAIL 12-PLAYER SPAWN COORDINATOR TEST SUITE")
    print("=================================================================")

    local testList = {
        "TEST_S01_UNIQUE_ALLOCATION_FOR_12_PLAYERS",
        "TEST_S02_CAPACITY_FALLBACK_BEYOND_12_PLAYERS",
        "TEST_S03_PLAYER_DISCONNECT_FREES_PAD",
    }

    for _, testName in ipairs(testList) do
        total += 1
        local fn = (Tests :: any)[testName]
        local success, err = pcall(fn)
        if success then
            passed += 1
            print(string.format("  [PASS] %s", testName))
        else
            failed += 1
            print(string.format("  [FAIL] %s: %s", testName, tostring(err)))
        end
    end

    print("=================================================================")
    print(string.format("  TOTAL: %d | PASSED: %d | FAILED: %d", total, passed, failed))
    print("=================================================================")

    return { total = total, passed = passed, failed = failed }
end

return {
    runAll = runAll,
}
