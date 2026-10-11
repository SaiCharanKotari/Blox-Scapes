--!strict
-- ClientNetwork.luau: Typed client network client for communicating with server remotes
-- Handles invocation timeouts, remote discovery, and profile synchronization

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")
local RemotesContract = require(BloomtrailShared:WaitForChild("Config"):WaitForChild("RemotesContract"))
local BoardTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("BoardTypes"))
local ProfileTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("ProfileTypes"))

type Coord = BoardTypes.Coord
type PlayerProfile = ProfileTypes.PlayerProfile

local ClientNetwork = {}

local remotesFolder: Folder? = nil

local function getRemotesFolder(): Folder?
    if not remotesFolder then
        remotesFolder = ReplicatedStorage:WaitForChild(RemotesContract.FOLDER_NAME, 5) :: Folder?
    end
    return remotesFolder
end

local function getRemoteFunction(name: string): RemoteFunction?
    local folder = getRemotesFolder()
    if folder then
        return folder:WaitForChild(name, 5) :: RemoteFunction?
    end
    return nil
end

local function getRemoteEvent(name: string): RemoteEvent?
    local folder = getRemotesFolder()
    if folder then
        return folder:WaitForChild(name, 5) :: RemoteEvent?
    end
    return nil
end

function ClientNetwork.getProfile(): PlayerProfile?
    local rf = getRemoteFunction(RemotesContract.GET_PLAYER_PROFILE)
    if rf then
        local success, res = pcall(function()
            return rf:InvokeServer()
        end)
        if success and res and res.success then
            return res.profile
        end
    end
    return nil
end

function ClientNetwork.requestStartLevel(levelId: number)
    local rf = getRemoteFunction(RemotesContract.REQUEST_START_LEVEL)
    if rf then
        local success, res = pcall(function()
            return rf:InvokeServer(levelId)
        end)
        if success and res then
            return res
        end
    end
    return { success = false, message = "Failed to communicate with server" }
end

function ClientNetwork.requestSwap(fromCoord: Coord, toCoord: Coord)
    local rf = getRemoteFunction(RemotesContract.REQUEST_SWAP)
    if rf then
        local success, res = pcall(function()
            return rf:InvokeServer(fromCoord, toCoord)
        end)
        if success and res then
            return res
        end
    end
    return { valid = false, message = "Network error during swap" }
end

function ClientNetwork.requestRestartLevel(levelId: number)
    local rf = getRemoteFunction(RemotesContract.REQUEST_RESTART_LEVEL)
    if rf then
        local success, res = pcall(function()
            return rf:InvokeServer(levelId)
        end)
        if success and res then
            return res
        end
    end
    return { success = false, message = "Failed to communicate with server" }
end

function ClientNetwork.requestCompleteTask(taskId: string)
    local rf = getRemoteFunction(RemotesContract.REQUEST_COMPLETE_TASK)
    if rf then
        local success, res = pcall(function()
            return rf:InvokeServer(taskId)
        end)
        if success and res then
            return res
        end
    end
    return { success = false, message = "Failed to communicate with server" }
end

function ClientNetwork.onProfileSynced(callback: (profile: PlayerProfile) -> ()): RBXScriptConnection?
    local re = getRemoteEvent(RemotesContract.SYNC_PROFILE_DATA)
    if re then
        return re.OnClientEvent:Connect(callback)
    end
    return nil
end

return ClientNetwork
