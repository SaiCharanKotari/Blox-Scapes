--!strict
-- PlayerCameraController.luau: Manages player-following third-person camera during exploration
-- Enforces CameraType.Custom and CameraSubject = Humanoid across spawns, deaths, and UI transitions

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local PlayerCameraController = {}

local localPlayer = Players.LocalPlayer
local currentHumanoid: Humanoid? = nil

local function bindHumanoid(humanoid: Humanoid)
    currentHumanoid = humanoid
    local camera = Workspace.CurrentCamera
    if camera then
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = humanoid
    end
end

local function onCharacterAdded(character: Model)
    local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
    if humanoid then
        bindHumanoid(humanoid)
    end
end

function PlayerCameraController.init()
    if localPlayer.Character then
        onCharacterAdded(localPlayer.Character)
    end
    localPlayer.CharacterAdded:Connect(onCharacterAdded)

    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        local camera = Workspace.CurrentCamera
        if camera and currentHumanoid and currentHumanoid.Parent then
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = currentHumanoid
        end
    end)
end

function PlayerCameraController.restoreFollow()
    local camera = Workspace.CurrentCamera
    if not camera then return end

    camera.CameraType = Enum.CameraType.Custom

    if not currentHumanoid or not currentHumanoid.Parent then
        local character = localPlayer.Character
        if character then
            currentHumanoid = character:FindFirstChildOfClass("Humanoid")
        end
    end

    if currentHumanoid then
        camera.CameraSubject = currentHumanoid
    end
end

return PlayerCameraController
