--!strict
-- ExplorationHUD.luau: Lightweight non-intrusive 3D world exploration HUD
-- Displays player resources and navigation triggers without blocking movement or camera controls

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")
local ProfileTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("ProfileTypes"))
local ThemeTokens = require(BloomtrailShared:WaitForChild("Config"):WaitForChild("ThemeTokens"))

local ResourceBadge = require(script.Parent.Parent.Common.ResourceBadge)

type PlayerProfile = ProfileTypes.PlayerProfile

export type ExplorationHUDProps = {
    profile: PlayerProfile,
    onOpenMap: () -> (),
    onOpenGarden: () -> (),
}

local function ExplorationHUD(props: ExplorationHUDProps)
    local profile = props.profile

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        -- Top Status Bar (Estate Title & Resources)
        TopBar = React.createElement("Frame", {
            Size = UDim2.new(1, -24, 0, 60),
            Position = UDim2.new(0.5, 0, 0, 48),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = ThemeTokens.Colors.ParchmentIvory,
            BorderSizePixel = 0,
            ZIndex = 10,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = ThemeTokens.Radii.Card }),
            Stroke = React.createElement("UIStroke", {
                Color = ThemeTokens.Colors.CedarUmber,
                Thickness = 2.5,
            }),

            -- Left: Estate Branding
            TitleLabel = React.createElement("TextLabel", {
                Size = UDim2.new(0, 200, 1, 0),
                Position = UDim2.new(0, 16, 0, 0),
                BackgroundTransparency = 1,
                Text = "🌸 BLOOMTRAIL ESTATE",
                Font = ThemeTokens.Typography.DisplayHero.Font,
                TextSize = 18,
                TextColor3 = ThemeTokens.Colors.CedarUmber,
                TextXAlignment = Enum.TextXAlignment.Left,
            }),

            -- Center: Stars & Coins Display
            ResourceSection = React.createElement("Frame", {
                Size = UDim2.new(0, 180, 1, 0),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
            }, {
                Layout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8),
                }),
                StarsBadge = React.createElement(ResourceBadge, {
                    kind = "star",
                    count = profile.stars,
                }),
                CoinsBadge = React.createElement(ResourceBadge, {
                    kind = "coin",
                    count = profile.coins,
                }),
            }),

            -- Right: Quick Action Buttons
            RightButtons = React.createElement("Frame", {
                Size = UDim2.new(0, 220, 1, 0),
                Position = UDim2.new(1, -12, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
            }, {
                Layout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8),
                }),

                -- Restoration Button
                GardenButton = React.createElement("TextButton", {
                    Size = UDim2.new(0, 104, 0, 38),
                    BackgroundColor3 = ThemeTokens.Colors.RiverStone,
                    Text = "FOUNTAIN ⛲",
                    Font = ThemeTokens.Typography.ButtonLabel.Font,
                    TextSize = 13,
                    TextColor3 = ThemeTokens.Colors.CedarUmber,
                    AutoButtonColor = true,
                    [React.Event.Activated] = props.onOpenGarden,
                }, {
                    Corner = React.createElement("UICorner", { CornerRadius = ThemeTokens.Radii.Pill }),
                    Stroke = React.createElement("UIStroke", {
                        Color = ThemeTokens.Colors.CedarUmber,
                        Thickness = 1.5,
                    }),
                }),

                -- World Map Button
                MapButton = React.createElement("TextButton", {
                    Size = UDim2.new(0, 96, 0, 38),
                    BackgroundColor3 = ThemeTokens.Colors.LeafSage,
                    Text = "MAP 🗺️",
                    Font = ThemeTokens.Typography.ButtonLabel.Font,
                    TextSize = 13,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    AutoButtonColor = true,
                    [React.Event.Activated] = props.onOpenMap,
                }, {
                    Corner = React.createElement("UICorner", { CornerRadius = ThemeTokens.Radii.Pill }),
                    Stroke = React.createElement("UIStroke", {
                        Color = ThemeTokens.Colors.BotanicalForest,
                        Thickness = 1.5,
                    }),
                }),
            }),
        }),

        -- Bottom Hint Pill
        BottomHint = React.createElement("Frame", {
            Size = UDim2.new(0, 340, 0, 36),
            Position = UDim2.new(0.5, 0, 1, -24),
            AnchorPoint = Vector2.new(0.5, 1),
            BackgroundColor3 = Color3.fromRGB(20, 28, 22),
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            ZIndex = 10,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = ThemeTokens.Radii.Pill }),
            Stroke = React.createElement("UIStroke", {
                Color = ThemeTokens.Colors.GoldAmber,
                Thickness = 1.2,
            }),
            HintText = React.createElement("TextLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "🌿 Explore grounds • Walk to Courtyard Fountain • Play Level 1",
                Font = ThemeTokens.Typography.BodyText.Font,
                TextSize = 13,
                TextColor3 = Color3.fromRGB(240, 245, 240),
            }),
        }),
    })
end

return ExplorationHUD
