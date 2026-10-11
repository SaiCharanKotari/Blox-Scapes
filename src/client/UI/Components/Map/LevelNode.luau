--!strict
-- LevelNode.luau: Declarative React-Lua progression medallion node for the storybook trail
-- Complies strictly with docs/ART_BIBLE.md Section 5.2

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")
local ThemeTokens = require(BloomtrailShared:WaitForChild("Config"):WaitForChild("ThemeTokens"))

export type LevelNodeProps = {
    levelNumber: number,
    state: "Completed" | "Current" | "Locked" | "ComingSoon",
    starsEarned: number?,
    position: UDim2,
    onActivated: (levelNumber: number) -> (),
}

local function LevelNode(props: LevelNodeProps)
    local state = props.state
    local levelNum = props.levelNumber

    local isCompleted = state == "Completed"
    local isCurrent = state == "Current"
    local isLocked = state == "Locked"
    local isComingSoon = state == "ComingSoon"

    -- Colors based on state
    local discColor = if isCompleted then ThemeTokens.Colors.CedarUmber
        elseif isCurrent then ThemeTokens.Colors.CedarUmber
        elseif isComingSoon then Color3.fromRGB(130, 95, 65)
        else ThemeTokens.Colors.RiverStone -- Locked stone disc

    local textColor = if isLocked then Color3.fromRGB(130, 120, 110) else ThemeTokens.Colors.ParchmentIvory

    return React.createElement("Frame", {
        Size = UDim2.fromOffset(72, 72),
        Position = props.position,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
    }, {
        -- Main Button Medallion
        Medallion = React.createElement("TextButton", {
            Size = if isCurrent then UDim2.fromScale(1.08, 1.08) else UDim2.fromScale(1, 1),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = discColor,
            BorderSizePixel = 0,
            AutoButtonColor = not isLocked,
            Text = "",
            ZIndex = 5,
            [React.Event.Activated] = function()
                props.onActivated(levelNum)
            end,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ThemeTokens.Radii.Pill,
            }),

            -- Outer Stroke: StarGold for current active node, DeepEspresso for completed/locked
            Stroke = React.createElement("UIStroke", {
                Color = if isCurrent then ThemeTokens.Colors.StarGold else ThemeTokens.Colors.DeepEspresso,
                Thickness = if isCurrent then 4 else 3,
            }),

            -- Number Label or Lock Icon
            ContentLabel = React.createElement("TextLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = if isLocked then "🔒" else tostring(levelNum),
                Font = ThemeTokens.Typography.DisplayHero.Font,
                TextSize = if isLocked then 22 else 24,
                TextColor3 = textColor,
            }),

            -- Subtle 3D Top Bevel Highlight
            TopBevel = not isLocked and React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0.35, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0.78,
                BorderSizePixel = 0,
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = ThemeTokens.Radii.Pill }),
            }),
        }),

        -- Active Node "PLAY" Tag
        PlayTag = isCurrent and React.createElement("Frame", {
            Size = UDim2.new(0, 48, 0, 20),
            Position = UDim2.new(0.5, 0, 0, -10),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = ThemeTokens.Colors.SproutLime,
            BorderSizePixel = 0,
            ZIndex = 5,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = ThemeTokens.Radii.Badge }),
            Stroke = React.createElement("UIStroke", {
                Color = ThemeTokens.Colors.BotanicalForest,
                Thickness = 1.5,
            }),
            Label = React.createElement("TextLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "PLAY",
                Font = ThemeTokens.Typography.ButtonLabel.Font,
                TextSize = 10,
                TextColor3 = Color3.fromRGB(255, 255, 255),
            }),
        }),

        -- Completed Node Stars Bar
        StarsUnder = isCompleted and React.createElement("Frame", {
            Size = UDim2.new(0, 52, 0, 16),
            Position = UDim2.new(0.5, 0, 1, 6),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
        }, {
            StarsLabel = React.createElement("TextLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "⭐⭐⭐",
                TextSize = 11,
            }),
        }),
    })
end

return LevelNode
