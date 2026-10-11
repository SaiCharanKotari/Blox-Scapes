--!strict
-- MatchGrid.luau: Declarative 8x8 carved cedar wood board with dual-layer slot and tile architecture
-- Completely replaces UIGridLayout with explicit coordinate slots and controlled animation layers

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")
local BoardTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("BoardTypes"))
local BoardCoord = require(BloomtrailShared:WaitForChild("Utils"):WaitForChild("BoardCoord"))
local ThemeTokens = require(BloomtrailShared:WaitForChild("Config"):WaitForChild("ThemeTokens"))

local TileView = require(script.Parent.TileView)

type Coord = BoardTypes.Coord
type Tile = BoardTypes.Tile

export type DisplayTile = {
    id: string,
    coord: Coord,
    tile: Tile,
}

export type MatchGridProps = {
    width: number,
    height: number,
    displayTiles: { [string]: DisplayTile },
    selectedCoord: Coord?,
    effectsOverlayRef: any,
    registerTileRef: (id: string, rbx: GuiObject?) -> (),
    onTileClicked: (coord: Coord) -> (),
}

local function MatchGrid(props: MatchGridProps)
    local width = props.width
    local height = props.height
    local displayTiles = props.displayTiles
    local selectedCoord = props.selectedCoord

    -- 1. Static 8x8 Background Sockets and Hit Detectors
    local slotChildren: { [string]: any } = {}
    for y = 1, height do
        for x = 1, width do
            local coord = BoardCoord.create(x, y)
            local isSelected = selectedCoord ~= nil and BoardCoord.equals(selectedCoord, coord)

            slotChildren[string.format("Slot_%d_%d", x, y)] = React.createElement("Frame", {
                Size = UDim2.new(1 / width, 0, 1 / height, 0),
                Position = UDim2.new((x - 1) / width, 0, (y - 1) / height, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, {
                SocketBevel = React.createElement("Frame", {
                    Size = UDim2.new(1, -4, 1, -4),
                    Position = UDim2.fromScale(0.5, 0.5),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = if isSelected then Color3.fromRGB(68, 48, 28) else Color3.fromRGB(36, 21, 11),
                    BorderSizePixel = 0,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = UDim.new(0, 8),
                    }),
                    SocketStroke = isSelected and React.createElement("UIStroke", {
                        Color = ThemeTokens.Colors.StarGold,
                        Thickness = 2,
                        Transparency = 0.3,
                    }),
                }),

                -- Dedicated Tap / Click Surface
                HitButton = React.createElement("TextButton", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 15,
                    [React.Event.Activated] = function()
                        props.onTileClicked(coord)
                    end,
                }),
            })
        end
    end

    -- 2. Dynamic Visual Tile Layer
    local tileChildren: { [string]: any } = {}
    for id, dt in pairs(displayTiles) do
        local isSelected = selectedCoord ~= nil and BoardCoord.equals(selectedCoord, dt.coord)
        tileChildren[id] = React.createElement(TileView, {
            id = id,
            coord = dt.coord,
            tile = dt.tile,
            isSelected = isSelected,
            width = width,
            height = height,
            tileRef = function(rbx: GuiObject?)
                props.registerTileRef(id, rbx)
            end,
        })
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
            DominantAxis = Enum.DominantAxis.Height,
        }),

        OuterCorner = React.createElement("UICorner", {
            CornerRadius = ThemeTokens.Radii.Modal,
        }),

        OuterStroke = React.createElement("UIStroke", {
            Color = ThemeTokens.Colors.DeepEspresso,
            Thickness = 4,
        }),

        -- Inner Carved Board Inset
        InnerBoard = React.createElement("Frame", {
            Size = UDim2.new(1, -16, 1, -16),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(46, 27, 14),
            BorderSizePixel = 0,
        }, {
            InnerCorner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 12),
            }),

            -- Layer 1: Static Sockets & Hit Buttons
            SlotsLayer = React.createElement("Frame", {
                Size = UDim2.new(1, -8, 1, -8),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                ZIndex = 1,
            }, slotChildren),

            -- Layer 2: Animated Tiles Layer
            TilesLayer = React.createElement("Frame", {
                Size = UDim2.new(1, -8, 1, -8),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                ZIndex = 5,
            }, tileChildren),

            -- Layer 3: Particle Blast & Effects Overlay
            EffectsLayer = React.createElement("Frame", {
                ref = props.effectsOverlayRef,
                Size = UDim2.new(1, -8, 1, -8),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                ZIndex = 25,
            }),
        }),
    })
end

return MatchGrid
