--!strict
-- MatchGrid.luau: Declarative React-Lua 8x8 match-3 board frame and tile layout container
-- Sourced directly from docs/ART_BIBLE.md cedar wood and parchment framing specs

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")
local BoardTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("BoardTypes"))
local BoardCoord = require(BloomtrailShared:WaitForChild("Utils"):WaitForChild("BoardCoord"))
local ThemeTokens = require(BloomtrailShared:WaitForChild("Config"):WaitForChild("ThemeTokens"))

local TileView = require(script.Parent.TileView)

type Coord = BoardTypes.Coord
type Grid = BoardTypes.Grid

export type MatchGridProps = {
    grid: Grid,
    width: number,
    height: number,
    selectedCoord: Coord?,
    onTileClicked: (coord: Coord) -> (),
}

local function MatchGrid(props: MatchGridProps)
    local width = props.width
    local height = props.height
    local grid = props.grid
    local selectedCoord = props.selectedCoord

    local children: { [string]: any } = {}

    -- Grid layout for 8x8 squares
    children["UIGridLayout"] = React.createElement("UIGridLayout", {
        CellSize = UDim2.new(1 / width, -4, 1 / height, -4),
        CellPadding = UDim2.fromOffset(4, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })

    -- Populate all cells
    local order = 0
    for y = 1, height do
        for x = 1, width do
            order += 1
            local coord = BoardCoord.create(x, y)
            local tile = BoardCoord.getTile(grid, x, y)
            local isSelected = selectedCoord ~= nil and BoardCoord.equals(selectedCoord, coord)

            children[string.format("Tile_%d_%d", x, y)] = React.createElement(TileView, {
                coord = coord,
                tile = tile,
                isSelected = isSelected,
                layoutOrder = order,
                onTileClicked = props.onTileClicked,
            })
        end
    end

    return React.createElement("Frame", {
        Size = UDim2.new(0.92, 0, 0.92, 0),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = ThemeTokens.Colors.CedarUmber,
        BorderSizePixel = 0,
    }, {
        AspectRatio = React.createElement("UIAspectRatioConstraint", {
            AspectRatio = 1,
        }),

        OuterCorner = React.createElement("UICorner", {
            CornerRadius = ThemeTokens.Radii.Modal,
        }),

        OuterStroke = React.createElement("UIStroke", {
            Color = ThemeTokens.Colors.DeepEspresso,
            Thickness = 4,
        }),

        -- Inner Parchment Board Inset
        InnerBoard = React.createElement("Frame", {
            Size = UDim2.new(1, -16, 1, -16),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(45, 27, 14),
            BorderSizePixel = 0,
        }, {
            InnerCorner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 10),
            }),
            Tiles = React.createElement("Frame", {
                Size = UDim2.new(1, -8, 1, -8),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
            }, children),
        }),
    })
end

return MatchGrid
