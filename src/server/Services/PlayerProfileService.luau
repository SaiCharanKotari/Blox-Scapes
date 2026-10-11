--!strict
-- PlayerProfileService.luau: Server-authoritative in-memory profile manager and reward ledger
-- Enforces reward idempotency, progression unlocking, and garden task tracking

local ProfileTypes
if typeof(script) == "Instance" and script.Parent and typeof(game) == "Instance" then
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")
    ProfileTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("ProfileTypes"))
else
    ProfileTypes = require("../../shared/Types/ProfileTypes")
end

type PlayerProfile = ProfileTypes.PlayerProfile

local profiles: { [string]: PlayerProfile } = {}

local PlayerProfileService = {}

local function getUserId(playerOrId: any): string
    if typeof(playerOrId) == "Instance" and playerOrId:IsA("Player") then
        return tostring(playerOrId.UserId)
    elseif typeof(playerOrId) == "number" or typeof(playerOrId) == "string" then
        return tostring(playerOrId)
    end
    return "default_player"
end

function PlayerProfileService.getProfile(playerOrId: any): PlayerProfile
    local userId = getUserId(playerOrId)
    if not profiles[userId] then
        profiles[userId] = ProfileTypes.createDefaultProfile()
    end
    return profiles[userId]
end

-- Records level victory with strict reward idempotency
function PlayerProfileService.recordLevelWin(
    playerOrId: any,
    levelId: number,
    starReward: number,
    coinReward: number
): (PlayerProfile, boolean)
    local profile = PlayerProfileService.getProfile(playerOrId)
    local levelKey = tostring(levelId)

    if not profile.completedLevels[levelKey] then
        -- First-time victory: grant rewards and advance unlocked level
        profile.stars += starReward
        profile.coins += coinReward
        profile.unlockedLevel = math.max(profile.unlockedLevel, levelId + 1)
        profile.completedLevels[levelKey] = {
            starsEarned = 1,
            highscore = 1000,
            completedAt = os.time(),
        }
        profile.meta.lastSavedAt = os.time()
        return profile, true
    else
        -- Replay victory: zero additional currency or duplicate reward grants
        profile.meta.lastSavedAt = os.time()
        return profile, false
    end
end

-- Deducts stars and records garden restoration task
function PlayerProfileService.completeGardenTask(
    playerOrId: any,
    taskId: string,
    starCost: number,
    targetStage: number
): (boolean, PlayerProfile, string?)
    local profile = PlayerProfileService.getProfile(playerOrId)

    -- 1. Check if task already completed
    for _, completedId in ipairs(profile.gardenState.completedTasks) do
        if completedId == taskId then
            return false, profile, "Task is already completed"
        end
    end

    -- 2. Check sufficient star balance
    if profile.stars < starCost then
        return false, profile, "Insufficient stars to complete task"
    end

    -- 3. Execute authoritative deduction
    profile.stars -= starCost
    table.insert(profile.gardenState.completedTasks, taskId)
    profile.gardenState.currentStage = math.max(profile.gardenState.currentStage, targetStage)
    profile.meta.lastSavedAt = os.time()

    return true, profile, nil
end

-- Reset helper for tests
function PlayerProfileService._clearAllProfiles()
    table.clear(profiles)
end

return PlayerProfileService
