--!strict
-- GardenScreen.luau: Declarative React-Lua screen for the 3D Courtyard Garden restoration view
-- Coordinates camera focus, restoration task cards, and 3D visual transformations

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")
local ProfileTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("ProfileTypes"))
local ThemeTokens = require(BloomtrailShared:WaitForChild("Config"):WaitForChild("ThemeTokens"))

local BloomtrailClient = script:FindFirstAncestor("BloomtrailClient")
local GardenSceneManager = require(BloomtrailClient:WaitForChild("Controllers"):WaitForChild("GardenSceneManager"))
local ClientNetwork = require(BloomtrailClient:WaitForChild("Network"):WaitForChild("ClientNetwork"))
local TaskDrawer = require(script.Parent.TaskDrawer)
local ResourceBadge = require(script.Parent.Parent.Common.ResourceBadge)

type PlayerProfile = ProfileTypes.PlayerProfile

export type GardenScreenProps = {
    profile: PlayerProfile,
    onBackToMap: () -> (),
    onProfileUpdated: (profile: PlayerProfile) -> (),
}

local function GardenScreen(props: GardenScreenProps)
    local profile = props.profile
    local isRestored = table.find(profile.gardenState.completedTasks, "task_restore_fountain") ~= nil

    -- Camera and 3D scene lifecycle binding
    React.useEffect(function()
        GardenSceneManager.focusCamera()
        GardenSceneManager.setStage(profile.gardenState.currentStage, false)

        return function()
            GardenSceneManager.restoreCamera()
        end
    end, {})

    -- Handle Task Restoration Action
    local handleRestore = React.useCallback(function()
        local result = ClientNetwork.requestCompleteTask("task_restore_fountain")
        if result and result.success and result.updatedProfile then
            -- Trigger visible 3D transformation
            GardenSceneManager.setStage(1, true)
            props.onProfileUpdated(result.updatedProfile)
        end
    end, { props.onProfileUpdated })

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1, -- Translucent to showcase 3D garden
    }, {
        -- Top HUD Bar
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

            -- Left: Back to Map Button
            BackButton = React.createElement("TextButton", {
                Size = UDim2.new(0, 96, 0, 38),
                Position = UDim2.new(0, 12, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = ThemeTokens.Colors.RiverStone,
                Text = "← MAP",
                Font = ThemeTokens.Typography.ButtonLabel.Font,
                TextSize = 14,
                TextColor3 = ThemeTokens.Colors.CedarUmber,
                AutoButtonColor = true,
                [React.Event.Activated] = props.onBackToMap,
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = ThemeTokens.Radii.Pill }),
                Stroke = React.createElement("UIStroke", { Color = ThemeTokens.Colors.CedarUmber, Thickness = 1.5 }),
            }),

            -- Center: Title Label
            TitleLabel = React.createElement("TextLabel", {
                Size = UDim2.new(0, 180, 1, 0),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Text = "🌿 COURTYARD",
                Font = ThemeTokens.Typography.DisplayHero.Font,
                TextSize = 18,
                TextColor3 = ThemeTokens.Colors.CedarUmber,
            }),

            -- Right: Stars Counter
            StarsSection = React.createElement("Frame", {
                Size = UDim2.new(0, 80, 1, 0),
                Position = UDim2.new(1, -12, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
            }, {
                Badge = React.createElement(ResourceBadge, {
                    kind = "star",
                    count = profile.stars,
                }),
            }),
        }),

        -- Bottom Task Drawer Card
        TaskDrawer = React.createElement(TaskDrawer, {
            stars = profile.stars,
            isCompleted = isRestored,
            onRestore = handleRestore,
        }),
    })
end

return GardenScreen
