--!strict
-- PuzzleScreen.luau: Declarative React-Lua screen coordinating HUD, 8x8 match-3 grid, and victory/defeat modals
-- Integrates directly with pure Luau BoardLogic engine while keeping presentation reactive

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")
local BoardTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("BoardTypes"))
local LevelTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("LevelTypes"))
local BoardCoord = require(BloomtrailShared:WaitForChild("Utils"):WaitForChild("BoardCoord"))
local BoardLogic = require(BloomtrailShared:WaitForChild("Puzzle"):WaitForChild("BoardLogic"))
local ThemeTokens = require(BloomtrailShared:WaitForChild("Config"):WaitForChild("ThemeTokens"))
local LevelRegistry = require(BloomtrailShared:WaitForChild("Config"):WaitForChild("LevelRegistry"))

local HeaderHUD = require(script.Parent.HeaderHUD)
local MatchGrid = require(script.Parent.MatchGrid)

type Coord = BoardTypes.Coord
type BoardSession = BoardLogic.BoardSession

export type PuzzleScreenProps = {
    levelId: number?,
}

local function PuzzleScreen(props: PuzzleScreenProps)
    local levelId = props.levelId or 1
    local levelDef = LevelRegistry.getLevel(levelId) or {
        id = 1,
        title = "First Blooms",
        width = 8,
        height = 8,
        moveLimit = 25,
        allowedColors = { "Berry", "Leaf", "Blossom", "Dewdrop" },
        objectives = {
            { kind = "collect_color", color = "Leaf", targetCount = 15 },
            { kind = "collect_color", color = "Berry", targetCount = 10 },
        },
        starThresholds = { 1000, 2000, 3000 },
        coinReward = 50,
        starReward = 1,
    }

    -- React state for active session and selected coordinate
    local session, setSession = React.useState(function()
        return BoardLogic.createSession(levelDef)
    end)

    local selectedCoord, setSelectedCoord = React.useState(nil :: Coord?)
    local sessionVersion, setSessionVersion = React.useState(0)

    local handleRestart = React.useCallback(function()
        local newSession = BoardLogic.createSession(levelDef)
        setSelectedCoord(nil)
        setSession(newSession)
        setSessionVersion(function(v) return v + 1 end)
    end, { levelDef })

    local handleTileClick = React.useCallback(function(coord: Coord)
        if session.status ~= "InProgress" then
            return
        end

        if not selectedCoord then
            -- First tile selected
            setSelectedCoord(coord)
        else
            if BoardCoord.equals(selectedCoord, coord) then
                -- Deselect if tapping same tile
                setSelectedCoord(nil)
            elseif BoardCoord.isAdjacent(selectedCoord, coord) then
                -- Attempt swap
                if BoardLogic.validateSwap(session, selectedCoord, coord) then
                    local result = BoardLogic.executeSwap(session, selectedCoord, coord)
                    setSelectedCoord(nil)
                    -- Trigger React re-render by incrementing version
                    setSessionVersion(function(v) return v + 1 end)
                else
                    -- Invalid swap: select the newly tapped tile instead
                    setSelectedCoord(coord)
                end
            else
                -- Tapped non-adjacent tile: switch selection
                setSelectedCoord(coord)
            end
        end
    end, { session, selectedCoord })

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = ThemeTokens.Colors.BotanicalScrim,
        BorderSizePixel = 0,
    }, {
        -- Botanical Background Gradient
        BackgroundGradient = React.createElement("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 38, 26)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 22, 16)),
            }),
            Rotation = 90,
        }),

        -- Top Header HUD
        HUD = React.createElement(HeaderHUD, {
            levelTitle = levelDef.title,
            movesRemaining = session.movesRemaining,
            objectives = session.objectives,
            status = session.status,
            onRestart = handleRestart,
        }),

        -- Centered 8x8 Board Container
        BoardArea = React.createElement("Frame", {
            Size = UDim2.new(1, 0, 0.65, 0),
            Position = UDim2.fromScale(0.5, 0.54),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
        }, {
            Grid = React.createElement(MatchGrid, {
                grid = session.grid,
                width = session.width,
                height = session.height,
                selectedCoord = selectedCoord,
                onTileClicked = handleTileClick,
            }),
        }),

        -- VICTORY CELEBRATION MODAL OVERLAY
        VictoryOverlay = (session.status == "Won") and React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.45,
            ZIndex = 50,
        }, {
            ModalCard = React.createElement("Frame", {
                Size = UDim2.new(0, 320, 0, 240),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = ThemeTokens.Colors.ParchmentIvory,
                BorderSizePixel = 0,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ThemeTokens.Radii.Modal,
                }),
                Stroke = React.createElement("UIStroke", {
                    Color = ThemeTokens.Colors.CedarUmber,
                    Thickness = 4,
                }),
                Title = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 48),
                    Position = UDim2.new(0.5, 0, 0, 16),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = "🌸 LEVEL COMPLETE! 🌸",
                    Font = ThemeTokens.Typography.DisplayHero.Font,
                    TextSize = 22,
                    TextColor3 = ThemeTokens.Colors.CedarUmber,
                }),
                RewardText = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 36),
                    Position = UDim2.new(0.5, 0, 0, 72),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = "+1 STAR ⭐   +50 COINS 🪙",
                    Font = ThemeTokens.Typography.MetricValue.Font,
                    TextSize = 18,
                    TextColor3 = ThemeTokens.Colors.StarGold,
                }),
                ContinueButton = React.createElement("TextButton", {
                    Size = UDim2.new(0, 180, 0, 44),
                    Position = UDim2.new(0.5, 0, 1, -24),
                    AnchorPoint = Vector2.new(0.5, 1),
                    BackgroundColor3 = ThemeTokens.Colors.LeafSage,
                    Text = "PLAY AGAIN",
                    Font = ThemeTokens.Typography.ButtonLabel.Font,
                    TextSize = 16,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    [React.Event.Activated] = handleRestart,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ThemeTokens.Radii.Pill,
                    }),
                }),
            }),
        }),

        -- DEFEAT / OUT OF MOVES MODAL OVERLAY
        DefeatOverlay = (session.status == "Lost") and React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.45,
            ZIndex = 50,
        }, {
            ModalCard = React.createElement("Frame", {
                Size = UDim2.new(0, 320, 0, 220),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = ThemeTokens.Colors.ParchmentIvory,
                BorderSizePixel = 0,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = ThemeTokens.Radii.Modal,
                }),
                Stroke = React.createElement("UIStroke", {
                    Color = ThemeTokens.Colors.CedarUmber,
                    Thickness = 4,
                }),
                Title = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 48),
                    Position = UDim2.new(0.5, 0, 0, 16),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = "OUT OF MOVES",
                    Font = ThemeTokens.Typography.DisplayHero.Font,
                    TextSize = 22,
                    TextColor3 = ThemeTokens.Colors.BerryCrimson,
                }),
                Desc = React.createElement("TextLabel", {
                    Size = UDim2.new(1, -32, 0, 36),
                    Position = UDim2.new(0.5, 0, 0, 68),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = "Don't worry! Try again to earn your garden star.",
                    Font = ThemeTokens.Typography.BodyText.Font,
                    TextSize = 13,
                    TextColor3 = ThemeTokens.Colors.CedarUmber,
                    TextWrapped = true,
                }),
                RetryButton = React.createElement("TextButton", {
                    Size = UDim2.new(0, 160, 0, 44),
                    Position = UDim2.new(0.5, 0, 1, -24),
                    AnchorPoint = Vector2.new(0.5, 1),
                    BackgroundColor3 = ThemeTokens.Colors.SproutLime,
                    Text = "RETRY",
                    Font = ThemeTokens.Typography.ButtonLabel.Font,
                    TextSize = 16,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    [React.Event.Activated] = handleRestart,
                }, {
                    Corner = React.createElement("UICorner", {
                        CornerRadius = ThemeTokens.Radii.Pill,
                    }),
                }),
            }),
        }),
    })
end

return PuzzleScreen
