--!strict
-- HeaderHUD.luau: Declarative React-Lua top HUD header displaying moves, goals, and level status
-- Storybook timber and parchment styling with vector objective badges and responsive mobile layout

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")
local BoardTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("BoardTypes"))
local ThemeTokens = require(BloomtrailShared:WaitForChild("Config"):WaitForChild("ThemeTokens"))

local TileSilhouette = require(script.Parent.TileSilhouette)

type ObjectiveState = BoardTypes.ObjectiveState
type GameStatus = BoardTypes.GameStatus

export type HeaderHUDProps = {
    levelTitle: string,
    movesRemaining: number,
    objectives: { ObjectiveState },
    status: GameStatus,
    onRestart: () -> (),
    onReturnToMap: (() -> ())?,
}

local function HeaderHUD(props: HeaderHUDProps)
    local goalBadges: { [string]: any } = {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
        }),
    }

    for i, obj in ipairs(props.objectives) do
        local remaining = math.max(0, obj.targetCount - obj.currentCount)

        goalBadges[string.format("Goal_%d", i)] = React.createElement("Frame", {
            Size = UDim2.new(0, 72, 0, 38),
            BackgroundColor3 = if obj.completed then ThemeTokens.Colors.SproutLime else ThemeTokens.Colors.ParchmentIvory,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = ThemeTokens.Radii.Badge,
            }),
            Stroke = React.createElement("UIStroke", {
                Color = if obj.completed then ThemeTokens.Colors.BotanicalForest else ThemeTokens.Colors.CedarUmber,
                Thickness = 1.8,
            }),

            -- Icon Container or Done Checkmark
            Content = if obj.completed then React.createElement("TextLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "✔ DONE",
                Font = ThemeTokens.Typography.ButtonLabel.Font,
                TextSize = 13,
                TextColor3 = Color3.fromRGB(255, 255, 255),
            }) else React.createElement("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
            }, {
                SilhouetteBox = React.createElement("Frame", {
                    Size = UDim2.new(0, 24, 0, 24),
                    Position = UDim2.new(0, 6, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = if obj.color == "Berry" then ThemeTokens.Colors.BerryCrimson
                        elseif obj.color == "Leaf" then ThemeTokens.Colors.EmeraldLeaf
                        elseif obj.color == "Blossom" then ThemeTokens.Colors.BlossomYellow
                        elseif obj.color == "Dewdrop" then ThemeTokens.Colors.DewdropBlue
                        else ThemeTokens.Colors.PlumPurple,
                    BorderSizePixel = 0,
                }, {
                    Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    VectorShape = React.createElement(TileSilhouette, {
                        color = obj.color,
                        blocker = obj.blocker,
                        sizeScale = 0.78,
                    }),
                }),
                CountLabel = React.createElement("TextLabel", {
                    Size = UDim2.new(1, -34, 1, 0),
                    Position = UDim2.new(0, 32, 0, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(remaining),
                    Font = ThemeTokens.Typography.MetricValue.Font,
                    TextSize = 17,
                    TextColor3 = ThemeTokens.Colors.CedarUmber,
                    TextXAlignment = Enum.TextXAlignment.Center,
                }),
            }),
        })
    end

    return React.createElement("Frame", {
        Size = UDim2.new(1, -24, 0, 64),
        Position = UDim2.new(0.5, 0, 0, 48), -- Safe-area top margin
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = ThemeTokens.Colors.ParchmentIvory,
        BorderSizePixel = 0,
        ZIndex = 30,
    }, {
        Corner = React.createElement("UICorner", {
            CornerRadius = ThemeTokens.Radii.Card,
        }),
        Stroke = React.createElement("UIStroke", {
            Color = ThemeTokens.Colors.CedarUmber,
            Thickness = 2.5,
        }),

        -- Left Section: Level Title & Navigation Buttons
        LeftSection = React.createElement("Frame", {
            Size = UDim2.new(0.38, 0, 1, 0),
            Position = UDim2.new(0, 10, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
        }, {
            Layout = React.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 6),
            }),
            MapButton = props.onReturnToMap and React.createElement("TextButton", {
                Size = UDim2.new(0, 32, 0, 32),
                BackgroundColor3 = ThemeTokens.Colors.RiverStone,
                Text = "←",
                Font = ThemeTokens.Typography.DisplayHero.Font,
                TextSize = 18,
                TextColor3 = ThemeTokens.Colors.CedarUmber,
                AutoButtonColor = true,
                [React.Event.Activated] = props.onReturnToMap,
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = ThemeTokens.Radii.Pill }),
                Stroke = React.createElement("UIStroke", { Color = ThemeTokens.Colors.CedarUmber, Thickness = 1.5 }),
            }),
            RestartButton = React.createElement("TextButton", {
                Size = UDim2.new(0, 32, 0, 32),
                BackgroundColor3 = ThemeTokens.Colors.RiverStone,
                Text = "↺",
                Font = ThemeTokens.Typography.DisplayHero.Font,
                TextSize = 18,
                TextColor3 = ThemeTokens.Colors.CedarUmber,
                AutoButtonColor = true,
                [React.Event.Activated] = props.onRestart,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ThemeTokens.Radii.Pill,
                }),
                Stroke = React.createElement("UIStroke", {
                    Color = ThemeTokens.Colors.CedarUmber,
                    Thickness = 1.5,
                }),
            }),
            TitleLabel = React.createElement("TextLabel", {
                Size = UDim2.new(0, 90, 1, 0),
                BackgroundTransparency = 1,
                Text = props.levelTitle,
                Font = ThemeTokens.Typography.ButtonLabel.Font,
                TextSize = 14,
                TextColor3 = ThemeTokens.Colors.CedarUmber,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }),
        }),

        -- Center Section: Moves Remaining Pill Badge
        CenterMoves = React.createElement("Frame", {
            Size = UDim2.new(0, 84, 0, 48),
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
                Size = UDim2.fromScale(1, 0.56),
                Position = UDim2.fromScale(0.5, 0.32),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Text = tostring(props.movesRemaining),
                Font = ThemeTokens.Typography.MetricValue.Font,
                TextSize = 20,
                TextColor3 = ThemeTokens.Colors.DeepEspresso,
            }),
            MovesCaption = React.createElement("TextLabel", {
                Size = UDim2.fromScale(1, 0.38),
                Position = UDim2.fromScale(0.5, 0.74),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Text = "MOVES",
                Font = ThemeTokens.Typography.Caption.Font,
                TextSize = 10,
                TextColor3 = ThemeTokens.Colors.CedarUmber,
            }),
        }),

        -- Right Section: Goals Drawer
        RightGoals = React.createElement("Frame", {
            Size = UDim2.new(0.36, 0, 1, 0),
            Position = UDim2.new(1, -10, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
        }, goalBadges),
    })
end

return HeaderHUD
