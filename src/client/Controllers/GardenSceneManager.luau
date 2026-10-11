--!strict
-- GardenSceneManager.luau: Manages the 3D prototype courtyard fountain scene and camera transitions
-- Builds and transforms the Courtyard Fountain model strictly within Workspace.BloomtrailGarden

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local GardenSceneManager = {}

local gardenFolder: Folder? = nil
local fountainModel: Model? = nil
local overgrownVines: { BasePart } = {}
local waterParts: { BasePart } = {}
local waterEmitters: { ParticleEmitter } = {}

local originalCameraType: Enum.CameraType = Enum.CameraType.Custom
local originalCameraCFrame: CFrame = CFrame.new()

-- Builds the reproducible prototype courtyard fountain scene
function GardenSceneManager.ensureScene()
    local existing = Workspace:FindFirstChild("BloomtrailGarden") :: Folder?
    if existing then
        gardenFolder = existing
        fountainModel = existing:FindFirstChild("CourtyardFountain") :: Model?
        GardenSceneManager._cacheParts()
        return
    end

    local folder = Instance.new("Folder")
    folder.Name = "BloomtrailGarden"

    local fountain = Instance.new("Model")
    fountain.Name = "CourtyardFountain"
    fountain.Parent = folder

    -- 1. Courtyard Cobblestone Plaza Base
    local plaza = Instance.new("Part")
    plaza.Name = "CourtyardPlaza"
    plaza.Shape = Enum.PartType.Cylinder
    plaza.Size = Vector3.new(1, 38, 38)
    plaza.CFrame = CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90))
    plaza.Anchored = true
    plaza.CanCollide = true
    plaza.Material = Enum.Material.Cobblestone
    plaza.Color = Color3.fromRGB(180, 172, 160)
    plaza.Parent = fountain

    -- 2. Outer Carved Limestone Basin
    local basinRim = Instance.new("Part")
    basinRim.Name = "BasinRim"
    basinRim.Shape = Enum.PartType.Cylinder
    basinRim.Size = Vector3.new(3, 20, 20)
    basinRim.CFrame = CFrame.new(0, 2, 0) * CFrame.Angles(0, 0, math.rad(90))
    basinRim.Anchored = true
    basinRim.CanCollide = true
    basinRim.Material = Enum.Material.Limestone
    basinRim.Color = Color3.fromRGB(224, 218, 208)
    basinRim.Parent = fountain

    -- 3. Center Pedestal and Tiered Spout
    local pedestal = Instance.new("Part")
    pedestal.Name = "CenterPedestal"
    pedestal.Shape = Enum.PartType.Cylinder
    pedestal.Size = Vector3.new(5.5, 6, 6)
    pedestal.CFrame = CFrame.new(0, 4.25, 0) * CFrame.Angles(0, 0, math.rad(90))
    pedestal.Anchored = true
    pedestal.CanCollide = true
    pedestal.Material = Enum.Material.Limestone
    pedestal.Color = Color3.fromRGB(205, 198, 188)
    pedestal.Parent = fountain

    local upperTier = Instance.new("Part")
    upperTier.Name = "UpperTier"
    upperTier.Shape = Enum.PartType.Cylinder
    upperTier.Size = Vector3.new(1.5, 9, 9)
    upperTier.CFrame = CFrame.new(0, 6.25, 0) * CFrame.Angles(0, 0, math.rad(90))
    upperTier.Anchored = true
    upperTier.CanCollide = true
    upperTier.Material = Enum.Material.Limestone
    upperTier.Color = Color3.fromRGB(224, 218, 208)
    upperTier.Parent = fountain

    -- 4. Overgrowth Vines (Stage 0: Visible, Stage 1: Hidden)
    for i = 1, 6 do
        local angle = (i / 6) * math.pi * 2
        local vine = Instance.new("Part")
        vine.Name = "IvyOvergrowth_" .. i
        vine.Size = Vector3.new(2, 3.2, 1.2)
        local posX = math.cos(angle) * 9.8
        local posZ = math.sin(angle) * 9.8
        vine.CFrame = CFrame.new(posX, 2.2, posZ) * CFrame.Angles(0, -angle, math.rad(15))
        vine.Anchored = true
        vine.CanCollide = false
        vine.Material = Enum.Material.Grass
        vine.Color = Color3.fromRGB(38, 77, 43) -- Botanical Forest
        vine.Parent = fountain
    end

    -- 5. Restored Water Basin (Stage 0: Hidden, Stage 1: Visible)
    local waterDisc = Instance.new("Part")
    waterDisc.Name = "RestoredWaterSurface"
    waterDisc.Shape = Enum.PartType.Cylinder
    waterDisc.Size = Vector3.new(0.4, 18.2, 18.2)
    waterDisc.CFrame = CFrame.new(0, 3.2, 0) * CFrame.Angles(0, 0, math.rad(90))
    waterDisc.Anchored = true
    waterDisc.CanCollide = false
    waterDisc.Material = Enum.Material.Glass
    waterDisc.Color = Color3.fromRGB(42, 157, 143) -- Sky Dewdrop
    waterDisc.Transparency = 1
    waterDisc.Parent = fountain

    -- 6. Restored Water Spray Column & Particle Emitter
    local spraySpout = Instance.new("Part")
    spraySpout.Name = "WaterSpout"
    spraySpout.Size = Vector3.new(1, 1, 1)
    spraySpout.CFrame = CFrame.new(0, 7.2, 0)
    spraySpout.Anchored = true
    spraySpout.CanCollide = false
    spraySpout.Transparency = 1
    spraySpout.Parent = fountain

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "FountainSpray"
    emitter.Color = ColorSequence.new(Color3.fromRGB(180, 235, 255))
    emitter.LightEmission = 0.5
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.4),
        NumberSequenceKeypoint.new(1, 0.8),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 0.8),
    })
    emitter.Speed = NumberRange.new(8, 12)
    emitter.SpreadAngle = Vector2.new(25, 25)
    emitter.Rate = 40
    emitter.Lifetime = NumberRange.new(1.2, 1.6)
    emitter.Acceleration = Vector3.new(0, -18, 0)
    emitter.Enabled = false
    emitter.Parent = spraySpout

    folder.Parent = Workspace
    gardenFolder = folder
    fountainModel = fountain

    GardenSceneManager._cacheParts()
end

function GardenSceneManager._cacheParts()
    table.clear(overgrownVines)
    table.clear(waterParts)
    table.clear(waterEmitters)

    if not fountainModel then return end

    for _, child in ipairs(fountainModel:GetChildren()) do
        if string.sub(child.Name, 1, 14) == "IvyOvergrowth_" and child:IsA("BasePart") then
            table.insert(overgrownVines, child)
        elseif child.Name == "RestoredWaterSurface" and child:IsA("BasePart") then
            table.insert(waterParts, child)
        elseif child.Name == "WaterSpout" and child:IsA("BasePart") then
            local emitter = child:FindFirstChild("FountainSpray") :: ParticleEmitter?
            if emitter then
                table.insert(waterEmitters, emitter)
            end
        end
    end
end

-- Sets the visible restoration stage of the courtyard fountain
function GardenSceneManager.setStage(stage: number, animate: boolean?)
    GardenSceneManager.ensureScene()

    local isRestored = stage >= 1

    for _, vine in ipairs(overgrownVines) do
        if animate then
            TweenService:Create(vine, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Transparency = if isRestored then 1 else 0,
            }):Play()
        else
            vine.Transparency = if isRestored then 1 else 0
        end
    end

    for _, water in ipairs(waterParts) do
        if animate then
            TweenService:Create(water, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Transparency = if isRestored then 0.25 else 1,
            }):Play()
        else
            water.Transparency = if isRestored then 0.25 else 1
        end
    end

    for _, emitter in ipairs(waterEmitters) do
        emitter.Enabled = isRestored
    end
end

-- Smoothly points the camera to view the Courtyard Fountain
function GardenSceneManager.focusCamera()
    GardenSceneManager.ensureScene()
    local camera = Workspace.CurrentCamera
    if not camera then return end

    originalCameraType = camera.CameraType
    originalCameraCFrame = camera.CFrame

    camera.CameraType = Enum.CameraType.Scriptable

    local targetCFrame = CFrame.new(Vector3.new(0, 11, -22), Vector3.new(0, 3.5, 0))
    TweenService:Create(camera, TweenInfo.new(0.8, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
        CFrame = targetCFrame,
    }):Play()
end

-- Restores default camera control
function GardenSceneManager.restoreCamera()
    local camera = Workspace.CurrentCamera
    if not camera then return end

    camera.CameraType = Enum.CameraType.Custom
end

return GardenSceneManager
