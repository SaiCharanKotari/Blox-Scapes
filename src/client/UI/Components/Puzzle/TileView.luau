--!strict
-- TileView.luau: Declarative React-Lua tile component with vector silhouettes and tween refs
-- Free of UIGridLayout locks; positions are explicitly controlled by board coordinates

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")
local BoardTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("BoardTypes"))
local ThemeTokens = require(BloomtrailShared:WaitForChild("Config"):WaitForChild("ThemeTokens"))

local TileSilhouette = require(script.Parent.TileSilhouette)

type Coord = BoardTypes.Coord
type Tile = BoardTypes.Tile
type TileColor = BoardTypes.TileColor

export type TileViewProps = {
    id: string,
    coord: Coord,
    tile: Tile?,
    isSelected: boolean,
    width: number,
    height: number,
    tileRef: ((rbx: GuiObject?) -> ())?,
}

local COLOR_MAP: { [TileColor]: Color3 } = {
    Berry   = ThemeTokens.Colors.BerryCrimson,
    Leaf    = ThemeTokens.Colors.EmeraldLeaf,
    Blossom = ThemeTokens.Colors.BlossomYellow,
    Dewdrop = ThemeTokens.Colors.DewdropBlue,
    Plum    = ThemeTokens.Colors.PlumPurple,
}

local function TileView(props: TileViewProps)
    local tile = props.tile
    local isSelected = props.isSelected
    local coord = props.coord
    local width = props.width
    local height = props.height

    local isBomb = tile and tile.special == "BlossomBomb"
    local tileColor = if isBomb then Color3.fromRGB(255, 230, 120)
        elseif tile and tile.color and COLOR_MAP[tile.color] then COLOR_MAP[tile.color]
        else Color3.fromRGB(210, 195, 180)

    local posX = (coord.x - 1) / width
    local posY = (coord.y - 1) / height
    local sizeW = 1 / width
    local sizeH = 1 / height

    return React.createElement("Frame", {
        ref = props.tileRef,
        Size = UDim2.new(sizeW, 0, sizeH, 0),
        Position = UDim2.new(posX, 0, posY, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = if isSelected then 10 else 5,
    }, {
        TileToken = tile and React.createElement("Frame", {
            Name = "TileToken",
            Size = if isSelected then UDim2.new(1, -2, 1, -2) else UDim2.new(1, -6, 1, -6),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = tileColor,
            BorderSizePixel = 0,
            ZIndex = if isSelected then 11 else 6,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = if isBomb then UDim.new(0.5, 0) else ThemeTokens.Radii.Tile,
            }),

            -- Selection Highlight Glow
            SelectionStroke = isSelected and React.createElement("UIStroke", {
                Color = ThemeTokens.Colors.StarGold,
                Thickness = 3.5,
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),

            -- Dual-Coded Vector Silhouette
            Silhouette = React.createElement(TileSilhouette, {
                color = tile.color,
                special = tile.special,
                blocker = tile.blocker,
                sizeScale = 1,
            }),

            -- 3D Specular Top Bevel
            TopBevel = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0.28, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0.75,
                BorderSizePixel = 0,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 8),
                }),
            }),

            -- 3D Inset Bottom Shadow
            BottomShadow = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0.20, 0),
                Position = UDim2.new(0, 0, 0.80, 0),
                BackgroundColor3 = ThemeTokens.Colors.DeepEspresso,
                BackgroundTransparency = 0.75,
                BorderSizePixel = 0,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 8),
                }),
            }),
        }),
    })
end

return TileView
