--!strict
-- App.luau: Declarative React-Lua root application router for Project Bloomtrail
-- Manages screen routing between Exploration (3D world), WorldMap, PuzzleScreen, and GardenScreen

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")
local ProfileTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("ProfileTypes"))

local ExplorationHUD = require(script.Parent.Components.Exploration.ExplorationHUD)
local WorldMapView = require(script.Parent.Components.Map.WorldMapView)
local PuzzleScreen = require(script.Parent.Components.Puzzle.PuzzleScreen)
local GardenScreen = require(script.Parent.Components.Garden.GardenScreen)

local BloomtrailClient = script:FindFirstAncestor("BloomtrailClient")
local ClientNetwork = require(BloomtrailClient:WaitForChild("Network"):WaitForChild("ClientNetwork"))
local PlayerCameraController = require(BloomtrailClient:WaitForChild("Controllers"):WaitForChild("PlayerCameraController"))

type PlayerProfile = ProfileTypes.PlayerProfile
type ScreenName = "Exploration" | "WorldMap" | "Puzzle" | "Garden"

local function App()
    -- Start directly in the 3D world per Gate 3.2 requirements
    local currentScreen, setCurrentScreen = React.useState("Exploration" :: ScreenName)
    local activeLevelId, setActiveLevelId = React.useState(1)
    
    local profile, setProfile = React.useState(function()
        return ClientNetwork.getProfile() or ProfileTypes.createDefaultProfile()
    end)

    -- Subscribe to real-time profile sync updates from server
    React.useEffect(function()
        task.spawn(function()
            local serverProfile = ClientNetwork.getProfile()
            if serverProfile then
                setProfile(serverProfile)
            end
        end)

        local conn = ClientNetwork.onProfileSynced(function(newProfile)
            setProfile(newProfile)
        end)

        return function()
            if conn then
                conn:Disconnect()
            end
        end
    end, {})

    -- Screen Navigation Callbacks
    local handleOpenExploration = React.useCallback(function()
        setCurrentScreen("Exploration")
        PlayerCameraController.restoreFollow()
    end, {})

    local handleOpenMap = React.useCallback(function()
        setCurrentScreen("WorldMap")
    end, {})

    local handleOpenGarden = React.useCallback(function()
        setCurrentScreen("Garden")
    end, {})

    local handleSelectLevel = React.useCallback(function(levelId: number)
        setActiveLevelId(levelId)
        setCurrentScreen("Puzzle")
    end, {})

    local handleProfileUpdated = React.useCallback(function(newProfile: PlayerProfile)
        setProfile(newProfile)
    end, {})

    if currentScreen == "Puzzle" then
        return React.createElement(PuzzleScreen, {
            levelId = activeLevelId,
            onReturnToMap = handleOpenExploration,
            onOpenGarden = handleOpenGarden,
            onProfileUpdated = handleProfileUpdated,
        })
    elseif currentScreen == "Garden" then
        return React.createElement(GardenScreen, {
            profile = profile,
            onBackToMap = handleOpenExploration,
            onProfileUpdated = handleProfileUpdated,
        })
    elseif currentScreen == "WorldMap" then
        return React.createElement(WorldMapView, {
            profile = profile,
            onSelectLevel = handleSelectLevel,
            onOpenGarden = handleOpenGarden,
            onBackToExplore = handleOpenExploration,
        })
    else
        -- 3D Estate Exploration Screen (Default)
        return React.createElement(ExplorationHUD, {
            profile = profile,
            onOpenMap = handleOpenMap,
            onOpenGarden = handleOpenGarden,
        })
    end
end

return App
