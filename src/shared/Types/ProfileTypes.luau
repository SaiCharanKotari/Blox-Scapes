--!strict
-- ProfileTypes: Persistent player progression schema for Project Bloomtrail

export type LevelRecord = {
    starsEarned: number,
    highscore: number,
    completedAt: number,
}

export type GardenProgress = {
    currentArea: string,
    completedTasks: { string },
    currentStage: number,
}

export type PlayerMeta = {
    createdAt: number,
    lastSavedAt: number,
    sessionCount: number,
}

export type PlayerProfile = {
    schemaVersion: number,
    unlockedLevel: number,
    stars: number,
    coins: number,
    completedLevels: { [string]: LevelRecord }, -- levelId as string key for JSON/DataStore safety
    gardenState: GardenProgress,
    meta: PlayerMeta,
}

local ProfileTypes = {}

function ProfileTypes.createDefaultProfile(): PlayerProfile
    return {
        schemaVersion = 1,
        unlockedLevel = 1,
        stars = 0,
        coins = 100,
        completedLevels = {},
        gardenState = {
            currentArea = "CourtyardFountain",
            completedTasks = {},
            currentStage = 0,
        },
        meta = {
            createdAt = os.time(),
            lastSavedAt = os.time(),
            sessionCount = 1,
        },
    }
end

return ProfileTypes
