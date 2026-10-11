--!strict
-- TileSilhouette.luau: Declarative vector-sharp botanical tile silhouettes
-- Strictly complies with docs/ART_BIBLE.md dual-coding and zero-emoji specifications

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")
local BoardTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("BoardTypes"))
local ThemeTokens = require(BloomtrailShared:WaitForChild("Config"):WaitForChild("ThemeTokens"))

type TileColor = BoardTypes.TileColor
type SpecialPieceType = BoardTypes.SpecialPieceType
type BlockerType = BoardTypes.BlockerType

export type TileSilhouetteProps = {
    color: TileColor?,
    special: SpecialPieceType?,
    blocker: BlockerType?,
    sizeScale: number?,
}

local function TileSilhouette(props: TileSilhouetteProps)
    local color = props.color
    local special = props.special
    local blocker = props.blocker
    local scale = props.sizeScale or 1

    local children: { [string]: any } = {}

    if special == "BlossomBomb" then
        -- BlossomBomb: Radiant 6-petal floral rosette with golden aura and center star
        children["OuterGlow"] = React.createElement("Frame", {
            Size = UDim2.fromScale(0.92 * scale, 0.92 * scale),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = ThemeTokens.Colors.StarGold,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
        })

        children["PetalLayer1"] = React.createElement("Frame", {
            Size = UDim2.fromScale(0.74 * scale, 0.74 * scale),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 245, 220),
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
        })

        children["PetalLayer2"] = React.createElement("Frame", {
            Size = UDim2.fromScale(0.74 * scale, 0.74 * scale),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Rotation = 45,
            BackgroundColor3 = Color3.fromRGB(255, 245, 220),
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
        })

        children["CenterCore"] = React.createElement("Frame", {
            Size = UDim2.fromScale(0.42 * scale, 0.42 * scale),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = ThemeTokens.Colors.CoinAmber,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
            Spark = React.createElement("Frame", {
                Size = UDim2.fromScale(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Rotation = 45,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
            }),
        })

    elseif color == "Berry" then
        -- Apple Berry: Heart-tapered crimson fruit with sprout leaf top
        children["BerryBody"] = React.createElement("Frame", {
            Size = UDim2.fromScale(0.64 * scale, 0.62 * scale),
            Position = UDim2.fromScale(0.5, 0.56),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0.45, 0) }),
        })

        children["BerryStem"] = React.createElement("Frame", {
            Size = UDim2.fromScale(0.08 * scale, 0.16 * scale),
            Position = UDim2.fromScale(0.48, 0.22),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = ThemeTokens.Colors.CedarUmber,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 2) }),
        })

        children["BerryLeaf"] = React.createElement("Frame", {
            Size = UDim2.fromScale(0.24 * scale, 0.14 * scale),
            Position = UDim2.fromScale(0.60, 0.22),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Rotation = 35,
            BackgroundColor3 = ThemeTokens.Colors.SproutLime,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
        })

        children["GlossSpot"] = React.createElement("Frame", {
            Size = UDim2.fromScale(0.14 * scale, 0.14 * scale),
            Position = UDim2.fromScale(0.40, 0.44),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.4,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
        })

    elseif color == "Leaf" then
        -- Emerald Leaf: Pointed ovate diamond gem with center vein rib
        children["DiamondGem"] = React.createElement("Frame", {
            Size = UDim2.fromScale(0.54 * scale, 0.54 * scale),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Rotation = 45,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
        })

        children["VeinRib"] = React.createElement("Frame", {
            Size = UDim2.new(0, math.max(2, math.floor(3 * scale)), 0.62 * scale, 0),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = ThemeTokens.Colors.BotanicalForest,
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
        })

    elseif color == "Blossom" then
        -- Sun Blossom: 8-rounded-petal floral rosette with amber disc
        children["Petals0"] = React.createElement("Frame", {
            Size = UDim2.fromScale(0.56 * scale, 0.56 * scale),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
        })

        children["Petals45"] = React.createElement("Frame", {
            Size = UDim2.fromScale(0.56 * scale, 0.56 * scale),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Rotation = 45,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
        })

        children["CenterDisc"] = React.createElement("Frame", {
            Size = UDim2.fromScale(0.30 * scale, 0.30 * scale),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = ThemeTokens.Colors.CoinAmber,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
        })

    elseif color == "Dewdrop" then
        -- Water Dewdrop: Teardrop with rounded circular base and pointed apex
        children["DropBase"] = React.createElement("Frame", {
            Size = UDim2.fromScale(0.56 * scale, 0.56 * scale),
            Position = UDim2.fromScale(0.5, 0.58),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
        })

        children["DropPoint"] = React.createElement("Frame", {
            Size = UDim2.fromScale(0.38 * scale, 0.38 * scale),
            Position = UDim2.fromScale(0.5, 0.36),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Rotation = 45,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 3) }),
        })

        children["SpecularShine"] = React.createElement("Frame", {
            Size = UDim2.fromScale(0.12 * scale, 0.12 * scale),
            Position = UDim2.fromScale(0.42, 0.46),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
        })

    elseif color == "Plum" then
        -- Royal Plum: Symmetrical oval with central cleft indentation
        children["PlumBody"] = React.createElement("Frame", {
            Size = UDim2.fromScale(0.50 * scale, 0.64 * scale),
            Position = UDim2.fromScale(0.5, 0.52),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0.45, 0) }),
        })

        children["CleftLine"] = React.createElement("Frame", {
            Size = UDim2.new(0, math.max(2, math.floor(2 * scale)), 0.50 * scale, 0),
            Position = UDim2.fromScale(0.5, 0.52),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = ThemeTokens.Colors.DeepEspresso,
            BackgroundTransparency = 0.4,
            BorderSizePixel = 0,
        })
    end

    -- Ivy Blocker bramble overlay if tile is tangled
    if blocker == "Ivy" then
        children["IvyBramble1"] = React.createElement("Frame", {
            Size = UDim2.new(0.9 * scale, 0, 0, 6 * scale),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Rotation = 28,
            BackgroundColor3 = ThemeTokens.Colors.BotanicalForest,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 3) }),
        })

        children["IvyBramble2"] = React.createElement("Frame", {
            Size = UDim2.new(0.9 * scale, 0, 0, 6 * scale),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Rotation = -28,
            BackgroundColor3 = ThemeTokens.Colors.BotanicalForest,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 3) }),
        })
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
    }, children)
end

return TileSilhouette
