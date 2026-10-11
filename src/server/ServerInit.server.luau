--!strict
-- ServerInit: Server bootstrap entry point for Project Bloomtrail

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")

local ServerNetwork = require(script.Parent:WaitForChild("Network"):WaitForChild("ServerNetwork"))
local PlayerProfileService = require(script.Parent:WaitForChild("Services"):WaitForChild("PlayerProfileService"))

-- Initialize remotes before players connect
ServerNetwork.init()

Players.PlayerAdded:Connect(function(player)
    -- Initialize or load profile
    local profile = PlayerProfileService.getProfile(player)
    ServerNetwork.syncProfile(player)
    print(string.format("[Bloomtrail] Player profile initialized for %s (Stars: %d, Coins: %d, Unlocked: %d)",
        player.Name, profile.stars, profile.coins, profile.unlockedLevel))
end)

print("[Bloomtrail] Server initialized successfully.")
