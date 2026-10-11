--!strict
-- AnimationCoordinator.luau: Central move and cascade animation coordinator
-- Coordinates spatial tile tweens, invalid rebounds, pop clears, gravity drops, and Blossom Bomb blasts
-- Completely decoupled from pure simulation engine logic

local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")
local BoardTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("BoardTypes"))
local ThemeTokens = require(BloomtrailShared:WaitForChild("Config"):WaitForChild("ThemeTokens"))

type Coord = BoardTypes.Coord

local AnimationCoordinator = {}

-- Standard motion durations from docs/ART_BIBLE.md
local DURATION_SWAP = 0.18
local DURATION_REBOUND_HALF = 0.11
local DURATION_POP_CLEAR = 0.20
local DURATION_GRAVITY_DROP = 0.22
local DURATION_REFILL_DROP = 0.25
local DURATION_BLAST = 0.28

function AnimationCoordinator.cellToPosition(x: number, y: number, width: number, height: number): UDim2
    return UDim2.new((x - 1) / width, 0, (y - 1) / height, 0)
end

-- 1. ADJACENT TILE SWAP TWEEN
function AnimationCoordinator.animateSwap(
    instanceA: GuiObject?,
    coordA: Coord,
    instanceB: GuiObject?,
    coordB: Coord,
    width: number,
    height: number
)
    local targetPosA = AnimationCoordinator.cellToPosition(coordB.x, coordB.y, width, height)
    local targetPosB = AnimationCoordinator.cellToPosition(coordA.x, coordA.y, width, height)

    local tweenInfo = TweenInfo.new(DURATION_SWAP, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local tweenA = if instanceA and instanceA.Parent then TweenService:Create(instanceA, tweenInfo, { Position = targetPosA }) else nil
    local tweenB = if instanceB and instanceB.Parent then TweenService:Create(instanceB, tweenInfo, { Position = targetPosB }) else nil

    if tweenA then tweenA:Play() end
    if tweenB then tweenB:Play() end

    task.wait(DURATION_SWAP)
end

-- 2. INVALID SWAP REBOUND TWEEN
function AnimationCoordinator.animateInvalidRebound(
    instanceA: GuiObject?,
    coordA: Coord,
    instanceB: GuiObject?,
    coordB: Coord,
    width: number,
    height: number
)
    local origPosA = AnimationCoordinator.cellToPosition(coordA.x, coordA.y, width, height)
    local origPosB = AnimationCoordinator.cellToPosition(coordB.x, coordB.y, width, height)

    local midXA = coordA.x + (coordB.x - coordA.x) * 0.42
    local midYA = coordA.y + (coordB.y - coordA.y) * 0.42
    local midXB = coordB.x + (coordA.x - coordB.x) * 0.42
    local midYB = coordB.y + (coordA.y - coordB.y) * 0.42

    local midPosA = AnimationCoordinator.cellToPosition(midXA, midYA, width, height)
    local midPosB = AnimationCoordinator.cellToPosition(midXB, midYB, width, height)

    local forwardInfo = TweenInfo.new(DURATION_REBOUND_HALF, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    local returnInfo = TweenInfo.new(DURATION_REBOUND_HALF, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

    -- Slide towards each other
    local tweenForwardA = if instanceA and instanceA.Parent then TweenService:Create(instanceA, forwardInfo, { Position = midPosA }) else nil
    local tweenForwardB = if instanceB and instanceB.Parent then TweenService:Create(instanceB, forwardInfo, { Position = midPosB }) else nil

    if tweenForwardA then tweenForwardA:Play() end
    if tweenForwardB then tweenForwardB:Play() end
    task.wait(DURATION_REBOUND_HALF)

    -- Bounce back to original slots
    local tweenBackA = if instanceA and instanceA.Parent then TweenService:Create(instanceA, returnInfo, { Position = origPosA }) else nil
    local tweenBackB = if instanceB and instanceB.Parent then TweenService:Create(instanceB, returnInfo, { Position = origPosB }) else nil

    if tweenBackA then tweenBackA:Play() end
    if tweenBackB then tweenBackB:Play() end
    task.wait(DURATION_REBOUND_HALF)
end

-- 3. MATCH CLEAR / POP FEEDBACK
function AnimationCoordinator.animatePopClear(instances: { GuiObject })
    local popInfo = TweenInfo.new(DURATION_POP_CLEAR, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    local tokenTweens = {}

    for _, tileFrame in ipairs(instances) do
        if tileFrame and tileFrame.Parent then
            local token = tileFrame:FindFirstChild("TileToken") :: GuiObject?
            if token then
                local t = TweenService:Create(token, popInfo, {
                    Size = UDim2.fromScale(1.3, 1.3),
                    BackgroundTransparency = 1,
                })
                table.insert(tokenTweens, t)
                t:Play()
            end
        end
    end

    task.wait(DURATION_POP_CLEAR)
end

-- 4. BLOSSOM BOMB 3X3 BLAST SHOCKWAVE EFFECT
function AnimationCoordinator.animateBombBlast(
    overlayContainer: GuiObject?,
    centerCoord: Coord,
    width: number,
    height: number
)
    if not overlayContainer or not overlayContainer.Parent then
        return
    end

    local centerPos = AnimationCoordinator.cellToPosition(centerCoord.x, centerCoord.y, width, height)
    local cellWidthScale = 1 / width
    local cellHeightScale = 1 / height

    local blastRing = Instance.new("Frame")
    blastRing.Name = "BlastWave"
    blastRing.Size = UDim2.fromScale(cellWidthScale * 0.5, cellHeightScale * 0.5)
    blastRing.Position = UDim2.new(centerPos.X.Scale + cellWidthScale * 0.5, 0, centerPos.Y.Scale + cellHeightScale * 0.5, 0)
    blastRing.AnchorPoint = Vector2.new(0.5, 0.5)
    blastRing.BackgroundColor3 = ThemeTokens.Colors.StarGold
    blastRing.BackgroundTransparency = 0.2
    blastRing.BorderSizePixel = 0
    blastRing.ZIndex = 30

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = blastRing

    local stroke = Instance.new("UIStroke")
    stroke.Color = ThemeTokens.Colors.SproutLime
    stroke.Thickness = 4
    stroke.Transparency = 0
    stroke.Parent = blastRing

    blastRing.Parent = overlayContainer

    local blastInfo = TweenInfo.new(DURATION_BLAST, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tweenBlast = TweenService:Create(blastRing, blastInfo, {
        Size = UDim2.fromScale(cellWidthScale * 3.2, cellHeightScale * 3.2),
        BackgroundTransparency = 1,
    })
    local tweenStroke = TweenService:Create(stroke, blastInfo, {
        Transparency = 1,
        Thickness = 8,
    })

    tweenBlast:Play()
    tweenStroke:Play()

    task.delay(DURATION_BLAST + 0.05, function()
        blastRing:Destroy()
    end)
end

-- 5. GRAVITY FALL & TOP REFILL ENTRY
function AnimationCoordinator.animateGravityAndRefills(
    shiftList: { { instance: GuiObject, toCoord: Coord } },
    refillList: { { instance: GuiObject, toCoord: Coord, startYOffset: number } },
    width: number,
    height: number
)
    local gravityInfo = TweenInfo.new(DURATION_GRAVITY_DROP, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local refillInfo = TweenInfo.new(DURATION_REFILL_DROP, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    -- Animate falling shift tiles
    for _, shift in ipairs(shiftList) do
        local inst = shift.instance
        if inst and inst.Parent then
            local targetPos = AnimationCoordinator.cellToPosition(shift.toCoord.x, shift.toCoord.y, width, height)
            local t = TweenService:Create(inst, gravityInfo, { Position = targetPos })
            t:Play()
        end
    end

    -- Animate refilling tiles dropping in from the top
    for _, refill in ipairs(refillList) do
        local inst = refill.instance
        if inst and inst.Parent then
            local targetPos = AnimationCoordinator.cellToPosition(refill.toCoord.x, refill.toCoord.y, width, height)
            local spawnPos = AnimationCoordinator.cellToPosition(refill.toCoord.x, refill.toCoord.y - refill.startYOffset, width, height)
            inst.Position = spawnPos
            local t = TweenService:Create(inst, refillInfo, { Position = targetPos })
            t:Play()
        end
    end

    local maxWait = math.max(DURATION_GRAVITY_DROP, DURATION_REFILL_DROP)
    task.wait(maxWait)
end

return AnimationCoordinator
