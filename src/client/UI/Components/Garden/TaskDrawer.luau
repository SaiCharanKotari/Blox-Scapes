--!strict
-- TaskDrawer.luau: Declarative React-Lua garden restoration task card
-- Sourced directly from docs/ART_BIBLE.md storybook timber and parchment specs

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")
local ThemeTokens = require(BloomtrailShared:WaitForChild("Config"):WaitForChild("ThemeTokens"))

export type TaskDrawerProps = {
    stars: number,
    isCompleted: boolean,
    onRestore: () -> (),
}

local function TaskDrawer(props: TaskDrawerProps)
    local stars = props.stars
    local isCompleted = props.isCompleted
    local canAfford = stars >= 1

    local btnText = if isCompleted then "✔ BASIN RESTORED"
        elseif canAfford then "RESTORE (1 ⭐)"
        else "NEED 1 ⭐ (PLAY LEVEL 1)"

    local btnColor = if isCompleted then ThemeTokens.Colors.SproutLime
        elseif canAfford then ThemeTokens.Colors.SproutLime
        else ThemeTokens.Colors.RiverStone

    local btnTextColor = if isCompleted then Color3.fromRGB(255, 255, 255)
        elseif canAfford then Color3.fromRGB(255, 255, 255)
        else ThemeTokens.Colors.CedarUmber

    return React.createElement("Frame", {
        Size = UDim2.new(1, -32, 0, 130),
        Position = UDim2.new(0.5, 0, 1, -24),
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundColor3 = ThemeTokens.Colors.ParchmentIvory,
        BorderSizePixel = 0,
        ZIndex = 20,
    }, {
        Corner = React.createElement("UICorner", {
            CornerRadius = ThemeTokens.Radii.Modal,
        }),
        Stroke = React.createElement("UIStroke", {
            Color = ThemeTokens.Colors.CedarUmber,
            Thickness = 3,
        }),

        -- Card Header: Task Title & Star Cost Tag
        HeaderSection = React.createElement("Frame", {
            Size = UDim2.new(1, -24, 0, 32),
            Position = UDim2.new(0.5, 0, 0, 12),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
        }, {
            TitleLabel = React.createElement("TextLabel", {
                Size = UDim2.new(1, -70, 1, 0),
                BackgroundTransparency = 1,
                Text = "Restore Fountain Basin",
                Font = ThemeTokens.Typography.DisplayHero.Font,
                TextSize = 18,
                TextColor3 = ThemeTokens.Colors.CedarUmber,
                TextXAlignment = Enum.TextXAlignment.Left,
            }),
            CostBadge = not isCompleted and React.createElement("Frame", {
                Size = UDim2.new(0, 60, 0, 26),
                Position = UDim2.new(1, 0, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = ThemeTokens.Colors.StarGold,
                BorderSizePixel = 0,
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = ThemeTokens.Radii.Pill }),
                Stroke = React.createElement("UIStroke", { Color = ThemeTokens.Colors.CedarUmber, Thickness = 1.5 }),
                Label = React.createElement("TextLabel", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text = "1 ⭐",
                    Font = ThemeTokens.Typography.ButtonLabel.Font,
                    TextSize = 13,
                    TextColor3 = ThemeTokens.Colors.DeepEspresso,
                }),
            }),
        }),

        -- Description
        DescLabel = React.createElement("TextLabel", {
            Size = UDim2.new(1, -24, 0, 28),
            Position = UDim2.new(0.5, 0, 0, 44),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Text = "Clean away cracked stone and overgrowth to restore crystal flowing water.",
            Font = ThemeTokens.Typography.BodyText.Font,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(110, 90, 75),
            TextXAlignment = Enum.TextXAlignment.Left,
        }),

        -- Primary Restore Action Button
        ActionButton = React.createElement("TextButton", {
            Size = UDim2.new(1, -24, 0, 40),
            Position = UDim2.new(0.5, 0, 1, -12),
            AnchorPoint = Vector2.new(0.5, 1),
            BackgroundColor3 = btnColor,
            Text = btnText,
            Font = ThemeTokens.Typography.ButtonLabel.Font,
            TextSize = 15,
            TextColor3 = btnTextColor,
            AutoButtonColor = canAfford and not isCompleted,
            [React.Event.Activated] = function()
                if canAfford and not isCompleted then
                    props.onRestore()
                end
            end,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = ThemeTokens.Radii.Pill }),
            Stroke = React.createElement("UIStroke", {
                Color = if isCompleted or canAfford then ThemeTokens.Colors.BotanicalForest else ThemeTokens.Colors.CedarUmber,
                Thickness = 2,
            }),
        }),
    })
end

return TaskDrawer
