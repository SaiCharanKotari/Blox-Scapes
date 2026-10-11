--!strict
-- GameplayAuthority.luau: Server-authoritative match-3 session manager and move validator
-- Owns all active player board sessions, enforces anti-exploit checks, and executes pure BoardLogic

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")
local BoardTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("BoardTypes"))
local LevelTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("LevelTypes"))
local BoardCoord = require(BloomtrailShared:WaitForChild("Utils"):WaitForChild("BoardCoord"))
local BoardLogic = require(BloomtrailShared:WaitForChild("Puzzle"):WaitForChild("BoardLogic"))
local LevelRegistry = require(BloomtrailShared:WaitForChild("Config"):WaitForChild("LevelRegistry"))

local PlayerProfileService = require(script.Parent.PlayerProfileService)

type Coord = BoardTypes.Coord
type BoardSession = BoardLogic.BoardSession

type ActiveSessionData = {
    session: BoardSession,
    levelId: number,
    lastSwapTime: number,
    swapCountInWindow: number,
}

local activeSessions: { [string]: ActiveSessionData } = {}

local GameplayAuthority = {}

local function getUserId(playerOrId: any): string
    if typeof(playerOrId) == "Instance" and playerOrId:IsA("Player") then
        return tostring(playerOrId.UserId)
    elseif typeof(playerOrId) == "number" or typeof(playerOrId) == "string" then
        return tostring(playerOrId)
    end
    return "default_player"
end

function GameplayAuthority.startLevel(playerOrId: any, levelId: number)
    local userId = getUserId(playerOrId)
    local levelDef = LevelRegistry.getLevel(levelId)
    if not levelDef then
        return { success = false, message = "Level does not exist" }
    end

    local profile = PlayerProfileService.getProfile(playerOrId)
    if levelId > profile.unlockedLevel then
        return { success = false, message = "Level is locked" }
    end

    local serverSeed = math.random(1, 2147483647)
    local session = BoardLogic.createSession(levelDef, serverSeed)
    activeSessions[userId] = {
        session = session,
        levelId = levelId,
        lastSwapTime = os.clock(),
        swapCountInWindow = 0,
    }

    return {
        success = true,
        levelId = levelId,
        levelTitle = levelDef.title,
        width = session.width,
        height = session.height,
        moveLimit = session.movesRemaining,
        initialGrid = BoardCoord.cloneGrid(session.grid, session.width, session.height),
        objectives = table.clone(session.objectives),
    }
end

function GameplayAuthority.restartLevel(playerOrId: any, levelId: number)
    return GameplayAuthority.startLevel(playerOrId, levelId)
end

function GameplayAuthority.swapTiles(playerOrId: any, fromCoord: Coord, toCoord: Coord)
    local userId = getUserId(playerOrId)
    local sessionData = activeSessions[userId]

    if not sessionData then
        return { valid = false, message = "No active level session found" }
    end

    local session = sessionData.session
    if session.status ~= "InProgress" then
        return { valid = false, message = "Session is already finished" }
    end

    -- 1. Rate limiting: drop if excessive calls
    local now = os.clock()
    if now - sessionData.lastSwapTime < 1 then
        sessionData.swapCountInWindow += 1
        if sessionData.swapCountInWindow > 10 then
            return { valid = false, message = "Rate limit exceeded" }
        end
    else
        sessionData.lastSwapTime = now
        sessionData.swapCountInWindow = 1
    end

    -- 2. Coordinate bounds and Manhattan adjacency validation
    if not BoardCoord.isValid(fromCoord.x, fromCoord.y, session.width, session.height) or
       not BoardCoord.isValid(toCoord.x, toCoord.y, session.width, session.height) then
        return { valid = false, message = "Coordinates out of bounds" }
    end

    if not BoardCoord.isAdjacent(fromCoord, toCoord) then
        return { valid = false, message = "Swap coordinates must be orthogonally adjacent" }
    end

    -- 3. Execute authoritative swap in pure engine
    local swapResult = BoardLogic.executeSwap(session, fromCoord, toCoord)

    local approvedProfile = nil
    if swapResult.valid and session.status == "Won" then
        local levelDef = LevelRegistry.getLevel(sessionData.levelId)
        local starReward = if levelDef then levelDef.starReward else 1
        local coinReward = if levelDef then levelDef.coinReward else 50

        local updatedProfile, isFirstWin = PlayerProfileService.recordLevelWin(
            playerOrId,
            sessionData.levelId,
            starReward,
            coinReward
        )
        approvedProfile = updatedProfile
    end

    return {
        valid = swapResult.valid,
        cascadeSteps = swapResult.cascadeSteps,
        movesRemaining = session.movesRemaining,
        status = session.status,
        reshuffled = swapResult.reshuffled,
        approvedProfile = approvedProfile,
        objectives = table.clone(session.objectives),
        finalGrid = BoardCoord.cloneGrid(session.grid, session.width, session.height),
    }
end

function GameplayAuthority.getActiveSession(playerOrId: any): BoardSession?
    local userId = getUserId(playerOrId)
    local data = activeSessions[userId]
    return if data then data.session else nil
end

return GameplayAuthority
