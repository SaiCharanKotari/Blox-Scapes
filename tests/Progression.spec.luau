--!strict
-- Progression.spec.luau: Comprehensive Unit Tests for Player Progression, Reward Idempotency, and Garden Tasks
-- Runs headlessly under Lune CLI and Roblox Studio

local ProfileTypes = require("../src/shared/Types/ProfileTypes")
local GardenTaskRegistry = require("../src/shared/Config/GardenTaskRegistry")
local PlayerProfileService = require("../src/server/Services/PlayerProfileService")
local GardenService = require("../src/server/Services/GardenService")

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

-- TEST P01: DEFAULT PROFILE INITIALIZATION
function Tests.TEST_P01_DEFAULT_PROFILE_INITIALIZATION()
    PlayerProfileService._clearAllProfiles()
    local profile = PlayerProfileService.getProfile("test_user_1")

    assertEqual(profile.schemaVersion, 1, "Schema version must be 1")
    assertEqual(profile.unlockedLevel, 1, "Initial unlocked level must be 1")
    assertEqual(profile.stars, 0, "Initial stars balance must be 0")
    assertEqual(profile.coins, 100, "Initial coins balance must be 100")
    assertEqual(next(profile.completedLevels), nil, "Completed levels table must start empty")
    assertEqual(profile.gardenState.currentArea, "CourtyardFountain", "Initial area must be CourtyardFountain")
    assertEqual(profile.gardenState.currentStage, 0, "Initial garden restoration stage must be 0")
    assertEqual(#profile.gardenState.completedTasks, 0, "Completed tasks list must start empty")
end

-- TEST P02: FIRST-TIME WIN AWARDS REWARDS AND UNLOCKS LEVEL 2
function Tests.TEST_P02_FIRST_WIN_REWARD_AND_UNLOCK()
    PlayerProfileService._clearAllProfiles()
    local profile = PlayerProfileService.getProfile("test_user_2")

    local updatedProfile, isFirstWin = PlayerProfileService.recordLevelWin("test_user_2", 1, 1, 50)
    assertTrue(isFirstWin, "First win must report isFirstWin = true")
    assertEqual(updatedProfile.stars, 1, "Stars balance must increase by 1")
    assertEqual(updatedProfile.coins, 150, "Coins balance must increase by 50 (from 100 to 150)")
    assertEqual(updatedProfile.unlockedLevel, 2, "Unlocked level must advance to 2")
    assertTrue(updatedProfile.completedLevels["1"] ~= nil, "completedLevels['1'] must be recorded")
    assertEqual(updatedProfile.completedLevels["1"].starsEarned, 1, "Recorded stars earned must be 1")
end

-- TEST P03: REPLAY WIN IDEMPOTENCY (Zero duplicate rewards)
function Tests.TEST_P03_REPLAY_WIN_IDEMPOTENCY()
    PlayerProfileService._clearAllProfiles()
    -- Win Level 1 first time
    PlayerProfileService.recordLevelWin("test_user_3", 1, 1, 50)
    local afterFirstWin = PlayerProfileService.getProfile("test_user_3")
    local starsAfterFirst = afterFirstWin.stars
    local coinsAfterFirst = afterFirstWin.coins

    -- Replay Level 1 and win again
    local afterReplay, isFirstWin = PlayerProfileService.recordLevelWin("test_user_3", 1, 1, 50)
    assertFalse(isFirstWin, "Replay win must report isFirstWin = false")
    assertEqual(afterReplay.stars, starsAfterFirst, "Stars balance must NOT increase on replay")
    assertEqual(afterReplay.coins, coinsAfterFirst, "Coins balance must NOT increase on replay")
    assertEqual(afterReplay.unlockedLevel, 2, "Unlocked level must remain 2")
end

-- TEST P04: GARDEN TASK COMPLETION AND STAR DEDUCTION
function Tests.TEST_P04_TASK_COMPLETION_AND_STAR_DEDUCTION()
    PlayerProfileService._clearAllProfiles()
    -- Earn 1 star by winning Level 1
    PlayerProfileService.recordLevelWin("test_user_4", 1, 1, 50)
    local profileBefore = PlayerProfileService.getProfile("test_user_4")
    assertEqual(profileBefore.stars, 1, "User must have 1 star")

    -- Complete 'task_restore_fountain'
    local res = GardenService.completeTask("test_user_4", "task_restore_fountain")
    assertTrue(res.success, "Task completion must succeed")
    assertTrue(res.updatedProfile ~= nil, "Updated profile must be returned")
    local p = res.updatedProfile :: any
    assertEqual(p.stars, 0, "Star balance must be decremented from 1 to 0")
    assertEqual(p.gardenState.currentStage, 1, "Restoration stage must advance to 1")
    assertTrue(table.find(p.gardenState.completedTasks, "task_restore_fountain") ~= nil, "Task must be in completedTasks list")
end

-- TEST P05: INSUFFICIENT STARS REJECTION
function Tests.TEST_P05_INSUFFICIENT_STARS_REJECTION()
    PlayerProfileService._clearAllProfiles()
    local profile = PlayerProfileService.getProfile("test_user_5")
    assertEqual(profile.stars, 0, "User must have 0 stars")

    -- Attempt to complete task costing 1 star
    local res = GardenService.completeTask("test_user_5", "task_restore_fountain")
    assertFalse(res.success, "Task completion must fail with insufficient stars")
    assertEqual(profile.stars, 0, "Stars balance must remain 0")
    assertEqual(profile.gardenState.currentStage, 0, "Garden stage must remain 0")
    assertEqual(#profile.gardenState.completedTasks, 0, "No task must be added to completedTasks")
end

-- TEST P06: DUPLICATE TASK COMPLETION REJECTION
function Tests.TEST_P06_DUPLICATE_TASK_COMPLETION_REJECTION()
    PlayerProfileService._clearAllProfiles()
    -- Give user 2 stars
    PlayerProfileService.recordLevelWin("test_user_6", 1, 1, 50)
    local p = PlayerProfileService.getProfile("test_user_6")
    p.stars = 2 -- Manually grant an extra star to test deduction guard

    -- First completion succeeds
    local res1 = GardenService.completeTask("test_user_6", "task_restore_fountain")
    assertTrue(res1.success, "First task completion must succeed")
    assertEqual(p.stars, 1, "Star balance must be 1 after first completion")

    -- Second completion of same task must be rejected without star deduction
    local res2 = GardenService.completeTask("test_user_6", "task_restore_fountain")
    assertFalse(res2.success, "Second task completion must be rejected as duplicate")
    assertEqual(p.stars, 1, "Stars must NOT be deducted again")
end

-- TEST P07: UNKNOWN TASK IDENTIFIER REJECTION
function Tests.TEST_P07_UNKNOWN_TASK_REJECTION()
    PlayerProfileService._clearAllProfiles()
    local res = GardenService.completeTask("test_user_7", "non_existent_task")
    assertFalse(res.success, "Unknown task ID must be rejected")
end

function Tests.runAll(): { total: number, passed: number, failed: number }
    local total = 0
    local passed = 0
    local failed = 0

    print("=================================================================")
    print("  BLOOMTRAIL PROGRESSION & TASK TEST SUITE (Pure Luau)")
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
