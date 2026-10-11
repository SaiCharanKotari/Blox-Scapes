--!strict
-- TileView.luau: Declarative React-Lua component for individual match-3 board tiles
-- Supports touch & mouse tap-to-select, dual-coded visual shapes, and selection highlighting

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")
local BoardTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("BoardTypes"))
local ThemeTokens = require(BloomtrailShared:WaitForChild("Config"):WaitForChild("ThemeTokens"))

type Coord = BoardTypes.Coord
type Tile = BoardTypes.Tile
type TileColor = BoardTypes.TileColor

export type TileViewProps = {
    coord: Coord,
    tile: Tile?,
    isSelected: boolean,
    layoutOrder: number,
    onTileClicked: (coord: Coord) -> (),
}

local COLOR_MAP: { [TileColor]: Color3 } = {
    Berry   = ThemeTokens.Colors.BerryCrimson,
    Leaf    = ThemeTokens.Colors.EmeraldLeaf,
    Blossom = ThemeTokens.Colors.BlossomYellow,
    Dewdrop = ThemeTokens.Colors.DewdropBlue,
    Plum    = ThemeTokens.Colors.PlumPurple,
}

local GLYPH_TEXT: { [TileColor]: string } = {
    Berry   = "🍎",
    Leaf    = "🍃",
    Blossom = "🌻",
    Dewdrop = "💧",
    Plum    = "🍇",
}

local function TileView(props: TileViewProps)
    local tile = props.tile
    local isSelected = props.isSelected
    local coord = props.coord

    local tileColor = if tile and tile.color and COLOR_MAP[tile.color] 
        then COLOR_MAP[tile.color] 
        else Color3.fromRGB(200, 190, 180)

    local isBomb = tile and tile.special == "BlossomBomb"
    local glyph = if isBomb then "🌸" 
        elseif tile and tile.color and GLYPH_TEXT[tile.color] then GLYPH_TEXT[tile.color] 
        else ""

    return React.createElement("TextButton", {
        LayoutOrder = props.layoutOrder,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        [React.Event.Activated] = function()
            props.onTileClicked(coord)
        end,
    }, {
        -- Slot Background Bevel
        SlotBackground = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(60, 36, 18),
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 6),
            }),
        }),

        -- Active Tile Token Frame
        TileToken = tile and React.createElement("Frame", {
            Size = if isSelected then UDim2.fromScale(0.96, 0.96) else UDim2.fromScale(0.88, 0.88),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = if isBomb then Color3.fromRGB(255, 230, 120) else tileColor,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = if isBomb then UDim.new(0.5, 0) else ThemeTokens.Radii.Tile,
            }),

            -- Selection Glow Stroke
            SelectionStroke = isSelected and React.createElement("UIStroke", {
                Color = ThemeTokens.Colors.StarGold,
                Thickness = 3,
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),

            -- Dual-Coded Silhouette Glyph
            GlyphLabel = React.createElement("TextLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = glyph,
                TextSize = 22,
                Font = ThemeTokens.Typography.DisplayHero.Font,
                TextColor3 = Color3.fromRGB(255, 255, 255),
            }),

            -- Subtle 3D Top Bevel Highlight
            TopBevel = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0.25, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0.75,
                BorderSizePixel = 0,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                }),
            }),
        }),
    })
end

return TileView
