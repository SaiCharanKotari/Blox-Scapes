--!strict
-- RemotesContract.luau: Centralized network contract definitions and remote identifiers

local RemotesContract = {
    FOLDER_NAME = "BloomtrailRemotes",
    
    -- RemoteFunctions (Client -> Server request-response)
    GET_PLAYER_PROFILE = "GetPlayerProfile",
    REQUEST_START_LEVEL = "RequestStartLevel",
    REQUEST_SWAP = "RequestSwap",
    REQUEST_RESTART_LEVEL = "RequestRestartLevel",
    REQUEST_COMPLETE_TASK = "RequestCompleteTask",
    
    -- RemoteEvents (Server -> Client push notifications)
    SYNC_PROFILE_DATA = "SyncProfileData",
}

return RemotesContract
