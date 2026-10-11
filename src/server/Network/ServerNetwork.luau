--!strict
-- ServerNetwork.luau: Initializes and dispatches all RemoteFunctions and RemoteEvents
-- Guarantees remotes exist before clients attempt invocation

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")
local RemotesContract = require(BloomtrailShared:WaitForChild("Config"):WaitForChild("RemotesContract"))
local BoardTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("BoardTypes"))

local PlayerProfileService = require(script.Parent.Parent.Services.PlayerProfileService)
local GameplayAuthority = require(script.Parent.Parent.Services.GameplayAuthority)
local GardenService = require(script.Parent.Parent.Services.GardenService)

type Coord = BoardTypes.Coord

local ServerNetwork = {}

local remotesFolder: Folder
local syncProfileEvent: RemoteEvent

local function getOrCreateRemoteFunction(name: string): RemoteFunction
    local remote = remotesFolder:FindFirstChild(name) :: RemoteFunction?
    if not remote then
        remote = Instance.new("RemoteFunction")
        remote.Name = name
        remote.Parent = remotesFolder
    end
    return remote
end

local function getOrCreateRemoteEvent(name: string): RemoteEvent
    local remote = remotesFolder:FindFirstChild(name) :: RemoteEvent?
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = remotesFolder
    end
    return remote
end

function ServerNetwork.init()
    -- Create Remotes folder in ReplicatedStorage
    local existingFolder = ReplicatedStorage:FindFirstChild(RemotesContract.FOLDER_NAME) :: Folder?
    if not existingFolder then
        remotesFolder = Instance.new("Folder")
        remotesFolder.Name = RemotesContract.FOLDER_NAME
        remotesFolder.Parent = ReplicatedStorage
    else
        remotesFolder = existingFolder
    end

    -- 1. SyncProfileData RemoteEvent
    syncProfileEvent = getOrCreateRemoteEvent(RemotesContract.SYNC_PROFILE_DATA)

    -- 2. GetPlayerProfile RemoteFunction
    local getProfileRF = getOrCreateRemoteFunction(RemotesContract.GET_PLAYER_PROFILE)
    getProfileRF.OnServerInvoke = function(player: Player)
        local profile = PlayerProfileService.getProfile(player)
        return { success = true, profile = profile }
    end

    -- 3. RequestStartLevel RemoteFunction
    local startLevelRF = getOrCreateRemoteFunction(RemotesContract.REQUEST_START_LEVEL)
    startLevelRF.OnServerInvoke = function(player: Player, levelId: any)
        local numLevelId = tonumber(levelId) or 1
        return GameplayAuthority.startLevel(player, numLevelId)
    end

    -- 4. RequestSwap RemoteFunction
    local swapRF = getOrCreateRemoteFunction(RemotesContract.REQUEST_SWAP)
    swapRF.OnServerInvoke = function(player: Player, fromCoord: any, toCoord: any)
        if typeof(fromCoord) ~= "table" or typeof(toCoord) ~= "table" then
            return { valid = false, message = "Malformed coordinate parameters" }
        end
        local c1: Coord = { x = tonumber(fromCoord.x) or 1, y = tonumber(fromCoord.y) or 1 }
        local c2: Coord = { x = tonumber(toCoord.x) or 1, y = tonumber(toCoord.y) or 1 }
        local result = GameplayAuthority.swapTiles(player, c1, c2)

        if result.approvedProfile then
            syncProfileEvent:FireClient(player, result.approvedProfile)
        end
        return result
    end

    -- 5. RequestRestartLevel RemoteFunction
    local restartRF = getOrCreateRemoteFunction(RemotesContract.REQUEST_RESTART_LEVEL)
    restartRF.OnServerInvoke = function(player: Player, levelId: any)
        local numLevelId = tonumber(levelId) or 1
        return GameplayAuthority.restartLevel(player, numLevelId)
    end

    -- 6. RequestCompleteTask RemoteFunction
    local completeTaskRF = getOrCreateRemoteFunction(RemotesContract.REQUEST_COMPLETE_TASK)
    completeTaskRF.OnServerInvoke = function(player: Player, taskId: any)
        if typeof(taskId) ~= "string" then
            return { success = false, message = "Malformed task identifier" }
        end
        local result = GardenService.completeTask(player, taskId)
        if result.success and result.updatedProfile then
            syncProfileEvent:FireClient(player, result.updatedProfile)
        end
        return result
    end

    print("[Bloomtrail] Server network remotes initialized successfully.")
end

function ServerNetwork.syncProfile(player: Player)
    local profile = PlayerProfileService.getProfile(player)
    if syncProfileEvent then
        syncProfileEvent:FireClient(player, profile)
    end
end

return ServerNetwork
