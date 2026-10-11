--!strict
-- WorldMapView.luau: Declarative React-Lua vertically scrolling garden progression trail
-- Displays 10 numbered level medallions with active, completed, and locked states

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")
local ProfileTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("ProfileTypes"))
local ThemeTokens = require(BloomtrailShared:WaitForChild("Config"):WaitForChild("ThemeTokens"))

local LevelNode = require(script.Parent.LevelNode)
local ResourceBadge = require(script.Parent.Parent.Common.ResourceBadge)

type PlayerProfile = ProfileTypes.PlayerProfile

export type WorldMapViewProps = {
    profile: PlayerProfile,
    onSelectLevel: (levelId: number) -> (),
    onOpenGarden: () -> (),
}

-- Curving S-curve path node offsets (bottom-to-top layout in ScrollingFrame)
local NODE_POSITIONS = {
    [1]  = { x = 0.50, y = 700 },
    [2]  = { x = 0.32, y = 630 },
    [3]  = { x = 0.68, y = 560 },
    [4]  = { x = 0.35, y = 490 },
    [5]  = { x = 0.65, y = 420 },
    [6]  = { x = 0.30, y = 350 },
    [7]  = { x = 0.68, y = 280 },
    [8]  = { x = 0.36, y = 210 },
    [9]  = { x = 0.62, y = 140 },
    [10] = { x = 0.50, y = 70  },
}

local function WorldMapView(props: WorldMapViewProps)
    local profile = props.profile
    local previewModalText, setPreviewModalText = React.useState(nil :: string?)

    local handleNodeClick = React.useCallback(function(levelNum: number)
        if levelNum == 1 then
            props.onSelectLevel(1)
        elseif levelNum == 2 and profile.unlockedLevel >= 2 then
            setPreviewModalText("🌸 Level 2: Tangled Vines\nUnlocked! Full gameplay validation coming in the next milestone.")
        elseif profile.unlockedLevel < levelNum then
            setPreviewModalText(string.format("🔒 Level %d is Locked\nComplete Level %d to unlock this trail!", levelNum, levelNum - 1))
        else
            setPreviewModalText(string.format("Level %d preview coming soon!", levelNum))
        end
    end, { profile.unlockedLevel, props.onSelectLevel })

    local nodeElements: { [string]: any } = {}

    -- Background trail connectors
    nodeElements["TrailPathBacking"] = React.createElement("Frame", {
        Size = UDim2.new(0, 12, 0, 840),
        Position = UDim2.new(0.5, 0, 0, 30),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = ThemeTokens.Colors.RiverStone,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 1,
    }, {
        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
    })

    -- Populate 10 level medallions
    for i = 1, 10 do
        local pos = NODE_POSITIONS[i]
        local isCompleted = profile.completedLevels[tostring(i)] ~= nil
        local isCurrent = not isCompleted and (profile.unlockedLevel == i)
        local isComingSoon = not isCompleted and (profile.unlockedLevel >= i and i > 1)
        local isLocked = profile.unlockedLevel < i

        local nodeState: "Completed" | "Current" | "Locked" | "ComingSoon" = if isCompleted then "Completed"
            elseif isCurrent then "Current"
            elseif isComingSoon then "ComingSoon"
            else "Locked"

        nodeElements[string.format("Node_%d", i)] = React.createElement(LevelNode, {
            levelNumber = i,
            state = nodeState,
            starsEarned = if isCompleted then 3 else nil,
            position = UDim2.new(pos.x, 0, 0, pos.y),
            onActivated = handleNodeClick,
        })
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = ThemeTokens.Colors.BotanicalScrim,
        BorderSizePixel = 0,
    }, {
        -- Botanical Background Gradient
        BackgroundGradient = React.createElement("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 42, 28)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 22, 16)),
            }),
            Rotation = 90,
        }),

        -- Top Header HUD Bar
        TopHUD = React.createElement("Frame", {
            Size = UDim2.new(1, -24, 0, 64),
            Position = UDim2.new(0.5, 0, 0, 48),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = ThemeTokens.Colors.ParchmentIvory,
            BorderSizePixel = 0,
            ZIndex = 20,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = ThemeTokens.Radii.Card }),
            Stroke = React.createElement("UIStroke", {
                Color = ThemeTokens.Colors.CedarUmber,
                Thickness = 2.5,
            }),

            -- Left: Title
            TitleSection = React.createElement("TextLabel", {
                Size = UDim2.new(0, 110, 1, 0),
                Position = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                Text = "🌸 TRAIL",
                Font = ThemeTokens.Typography.DisplayHero.Font,
                TextSize = 20,
                TextColor3 = ThemeTokens.Colors.CedarUmber,
                TextXAlignment = Enum.TextXAlignment.Left,
            }),

            -- Center: Stars and Coins Badges
            ResourceSection = React.createElement("Frame", {
                Size = UDim2.new(0, 170, 1, 0),
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

            -- Right: Garden Courtyard Button
            GardenButton = React.createElement("TextButton", {
                Size = UDim2.new(0, 96, 0, 38),
                Position = UDim2.new(1, -12, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = ThemeTokens.Colors.LeafSage,
                Text = "GARDEN 🌿",
                Font = ThemeTokens.Typography.ButtonLabel.Font,
                TextSize = 13,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                AutoButtonColor = true,
                [React.Event.Activated] = props.onOpenGarden,
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = ThemeTokens.Radii.Pill }),
                Stroke = React.createElement("UIStroke", {
                    Color = ThemeTokens.Colors.BotanicalForest,
                    Thickness = 1.5,
                }),
            }),
        }),

        -- Scrolling Trail View
        TrailScroller = React.createElement("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, -120),
            Position = UDim2.new(0, 0, 0, 120),
            CanvasSize = UDim2.new(0, 0, 0, 780),
            CanvasPosition = Vector2.new(0, 380), -- Focus bottom near Level 1
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = ThemeTokens.Colors.RiverStone,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, nodeElements),

        -- Information / Coming Soon Dialog
        PreviewDialog = previewModalText and React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.5,
            ZIndex = 50,
        }, {
            Card = React.createElement("Frame", {
                Size = UDim2.new(0, 300, 0, 180),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = ThemeTokens.Colors.ParchmentIvory,
                BorderSizePixel = 0,
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = ThemeTokens.Radii.Modal }),
                Stroke = React.createElement("UIStroke", {
                    Color = ThemeTokens.Colors.CedarUmber,
                    Thickness = 3,
                }),
                TextLabel = React.createElement("TextLabel", {
                    Size = UDim2.new(1, -32, 0, 80),
                    Position = UDim2.new(0.5, 0, 0, 20),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = previewModalText,
                    Font = ThemeTokens.Typography.BodyText.Font,
                    TextSize = 14,
                    TextColor3 = ThemeTokens.Colors.CedarUmber,
                    TextWrapped = true,
                }),
                CloseButton = React.createElement("TextButton", {
                    Size = UDim2.new(0, 120, 0, 38),
                    Position = UDim2.new(0.5, 0, 1, -18),
                    AnchorPoint = Vector2.new(0.5, 1),
                    BackgroundColor3 = ThemeTokens.Colors.LeafSage,
                    Text = "OKAY",
                    Font = ThemeTokens.Typography.ButtonLabel.Font,
                    TextSize = 14,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    [React.Event.Activated] = function()
                        setPreviewModalText(nil)
                    end,
                }, {
                    Corner = React.createElement("UICorner", { CornerRadius = ThemeTokens.Radii.Pill }),
                }),
            }),
        }),
    })
end

return WorldMapView
