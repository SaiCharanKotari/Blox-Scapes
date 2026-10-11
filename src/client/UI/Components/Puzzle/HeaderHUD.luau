--!strict
-- HeaderHUD.luau: Declarative React-Lua top HUD header displaying moves, goals, and level status
-- Follows storybook timber & parchment specifications from docs/ART_BIBLE.md

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")
local BoardTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("BoardTypes"))
local ThemeTokens = require(BloomtrailShared:WaitForChild("Config"):WaitForChild("ThemeTokens"))

type ObjectiveState = BoardTypes.ObjectiveState
type GameStatus = BoardTypes.GameStatus

export type HeaderHUDProps = {
    levelTitle: string,
    movesRemaining: number,
    objectives: { ObjectiveState },
    status: GameStatus,
    onRestart: () -> (),
}

local function HeaderHUD(props: HeaderHUDProps)
    local goalBadges: { [string]: any } = {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
        }),
    }

    for i, obj in ipairs(props.objectives) do
        local glyph = if obj.color == "Leaf" then "🍃"
            elseif obj.color == "Berry" then "🍎"
            elseif obj.color == "Blossom" then "🌻"
            elseif obj.color == "Dewdrop" then "💧"
            else "⭐"

        local remaining = math.max(0, obj.targetCount - obj.currentCount)

        goalBadges[string.format("Goal_%d", i)] = React.createElement("Frame", {
            Size = UDim2.new(0, 68, 0, 36),
            BackgroundColor3 = if obj.completed then ThemeTokens.Colors.SproutLime else ThemeTokens.Colors.ParchmentIvory,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ThemeTokens.Radii.Badge,
            }),
            Stroke = React.createElement("UIStroke", {
                Color = ThemeTokens.Colors.CedarUmber,
                Thickness = 1.5,
            }),
            Label = React.createElement("TextLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = if obj.completed then "✔ Done" else string.format("%s %d", glyph, remaining),
                Font = ThemeTokens.Typography.BodyText.Font,
                TextSize = 13,
                TextColor3 = if obj.completed then Color3.fromRGB(255, 255, 255) else ThemeTokens.Colors.CedarUmber,
            }),
        })
    end

    return React.createElement("Frame", {
        Size = UDim2.new(1, -24, 0, 72),
        Position = UDim2.new(0.5, 0, 0, 48), -- Safe-area top margin
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = ThemeTokens.Colors.ParchmentIvory,
        BorderSizePixel = 0,
    }, {
        Corner = React.createElement("UICorner", {
            CornerRadius = ThemeTokens.Radii.Card,
        }),
        Stroke = React.createElement("UIStroke", {
            Color = ThemeTokens.Colors.CedarUmber,
            Thickness = 2.5,
        }),

        -- Left: Level Title & Restart Affordance
        LeftSection = React.createElement("Frame", {
            Size = UDim2.new(0.32, 0, 1, 0),
            BackgroundTransparency = 1,
        }, {
            Layout = React.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 6),
            }),
            Padding = React.createElement("UIPadding", {
                PaddingLeft = UDim.new(0, 12),
            }),
            RestartButton = React.createElement("TextButton", {
                Size = UDim2.new(0, 32, 0, 32),
                BackgroundColor3 = ThemeTokens.Colors.RiverStone,
                Text = "🔄",
                TextSize = 16,
                AutoButtonColor = true,
                [React.Event.Activated] = props.onRestart,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ThemeTokens.Radii.Pill,
                }),
            }),
            TitleLabel = React.createElement("TextLabel", {
                Size = UDim2.new(0, 80, 1, 0),
                BackgroundTransparency = 1,
                Text = props.levelTitle,
                Font = ThemeTokens.Typography.ButtonLabel.Font,
                TextSize = 15,
                TextColor3 = ThemeTokens.Colors.CedarUmber,
                TextXAlignment = Enum.TextXAlignment.Left,
            }),
        }),

        -- Center: Moves Remaining Badge
        CenterMoves = React.createElement("Frame", {
            Size = UDim2.new(0, 96, 0, 48),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = ThemeTokens.Colors.StarGold,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ThemeTokens.Radii.Pill,
            }),
            Stroke = React.createElement("UIStroke", {
                Color = ThemeTokens.Colors.CedarUmber,
                Thickness = 2,
            }),
            MovesText = React.createElement("TextLabel", {
                Size = UDim2.fromScale(1, 0.55),
                Position = UDim2.fromScale(0.5, 0.3),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Text = tostring(props.movesRemaining),
                Font = ThemeTokens.Typography.MetricValue.Font,
                TextSize = 22,
                TextColor3 = ThemeTokens.Colors.DeepEspresso,
            }),
            MovesCaption = React.createElement("TextLabel", {
                Size = UDim2.fromScale(1, 0.4),
                Position = UDim2.fromScale(0.5, 0.75),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Text = "MOVES",
                Font = ThemeTokens.Typography.Caption.Font,
                TextSize = 10,
                TextColor3 = ThemeTokens.Colors.CedarUmber,
            }),
        }),

        -- Right: Goal Badges Drawer
        RightGoals = React.createElement("Frame", {
            Size = UDim2.new(0.35, 0, 1, 0),
            Position = UDim2.new(1, -12, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
        }, goalBadges),
    })
end

return HeaderHUD
