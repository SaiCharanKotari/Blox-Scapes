--!strict
-- ResourceBadge.luau: Declarative React-Lua currency badge for stars and coins
-- Sourced directly from docs/ART_BIBLE.md design tokens

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")
local ThemeTokens = require(BloomtrailShared:WaitForChild("Config"):WaitForChild("ThemeTokens"))

export type ResourceBadgeProps = {
    kind: "star" | "coin",
    count: number,
}

local function ResourceBadge(props: ResourceBadgeProps)
    local isStar = props.kind == "star"
    local bgColor = if isStar then ThemeTokens.Colors.StarGold else ThemeTokens.Colors.CoinAmber
    local iconText = if isStar then "⭐" else "🪙"

    return React.createElement("Frame", {
        Size = UDim2.new(0, 78, 0, 34),
        BackgroundColor3 = ThemeTokens.Colors.ParchmentIvory,
        BorderSizePixel = 0,
    }, {
        Corner = React.createElement("UICorner", {
            CornerRadius = ThemeTokens.Radii.Pill,
        }),
        Stroke = React.createElement("UIStroke", {
            Color = ThemeTokens.Colors.CedarUmber,
            Thickness = 2,
        }),
        IconBadge = React.createElement("Frame", {
            Size = UDim2.new(0, 26, 0, 26),
            Position = UDim2.new(0, 4, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = bgColor,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
            Label = React.createElement("TextLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = iconText,
                TextSize = 14,
            }),
        }),
        CountLabel = React.createElement("TextLabel", {
            Size = UDim2.new(1, -34, 1, 0),
            Position = UDim2.new(0, 32, 0, 0),
            BackgroundTransparency = 1,
            Text = tostring(props.count),
            Font = ThemeTokens.Typography.MetricValue.Font,
            TextSize = 15,
            TextColor3 = ThemeTokens.Colors.DeepEspresso,
            TextXAlignment = Enum.TextXAlignment.Center,
        }),
    })
end

return ResourceBadge
