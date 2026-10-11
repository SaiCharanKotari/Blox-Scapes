--!strict
-- ClientInit: Client entry point for Project Bloomtrail
-- Mounts declarative React-Lua UI root into PlayerGui

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))
local ReactRoblox = require(Packages:WaitForChild("ReactRoblox"))

local App = require(script.Parent:WaitForChild("UI"):WaitForChild("App"))
local GardenSceneManager = require(script.Parent:WaitForChild("Controllers"):WaitForChild("GardenSceneManager"))
local PlayerCameraController = require(script.Parent:WaitForChild("Controllers"):WaitForChild("PlayerCameraController"))

-- Initialize robust player camera tracking
PlayerCameraController.init()

-- Ensure Courtyard Garden scene exists in Workspace
GardenSceneManager.ensureScene()

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local screenGui = playerGui:FindFirstChild("BloomtrailGui")
if not screenGui then
    local newGui = Instance.new("ScreenGui")
    newGui.Name = "BloomtrailGui"
    newGui.ResetOnSpawn = false
    newGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    newGui.IgnoreGuiInset = true
    newGui.Parent = playerGui
    screenGui = newGui
end

local root = ReactRoblox.createRoot(screenGui)
root:render(React.createElement(App))

print("[Bloomtrail] React-Lua client UI mounted successfully.")
