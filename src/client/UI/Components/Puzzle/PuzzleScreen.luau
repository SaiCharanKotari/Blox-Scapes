--!strict
-- PuzzleScreen.luau: Declarative React-Lua screen coordinating HUD, animated 8x8 match-3 grid, and victory/defeat modals
-- Integrates with server authority via ClientNetwork and pure Luau BoardLogic simulation engine

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")
local BoardTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("BoardTypes"))
local LevelTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("LevelTypes"))
local ProfileTypes = require(BloomtrailShared:WaitForChild("Types"):WaitForChild("ProfileTypes"))
local BoardCoord = require(BloomtrailShared:WaitForChild("Utils"):WaitForChild("BoardCoord"))
local BoardLogic = require(BloomtrailShared:WaitForChild("Puzzle"):WaitForChild("BoardLogic"))
local ThemeTokens = require(BloomtrailShared:WaitForChild("Config"):WaitForChild("ThemeTokens"))
local LevelRegistry = require(BloomtrailShared:WaitForChild("Config"):WaitForChild("LevelRegistry"))

local HeaderHUD = require(script.Parent.HeaderHUD)
local MatchGrid = require(script.Parent.MatchGrid)
local AnimationCoordinator = require(script.Parent.AnimationCoordinator)

local BloomtrailClient = script:FindFirstAncestor("BloomtrailClient")
local ClientNetwork = require(BloomtrailClient:WaitForChild("Network"):WaitForChild("ClientNetwork"))

type Coord = BoardTypes.Coord
type Grid = BoardTypes.Grid
type Tile = BoardTypes.Tile
type BoardSession = BoardLogic.BoardSession
type GameStatus = BoardTypes.GameStatus
type ObjectiveState = BoardTypes.ObjectiveState
type PlayerProfile = ProfileTypes.PlayerProfile
type DisplayTile = MatchGrid.DisplayTile

export type PuzzleScreenProps = {
    levelId: number?,
    onReturnToMap: (() -> ())?,
    onOpenGarden: (() -> ())?,
    onProfileUpdated: ((profile: PlayerProfile) -> ())?,
}

-- Helper to convert authoritative grid into presentation tiles dictionary
local function createDisplayTilesFromGrid(grid: Grid, width: number, height: number): { [string]: DisplayTile }
    local tiles: { [string]: DisplayTile } = {}
    for y = 1, height do
        for x = 1, width do
            local tile = BoardCoord.getTile(grid, x, y)
            if tile then
                tiles[tile.id] = {
                    id = tile.id,
                    coord = BoardCoord.create(x, y),
                    tile = tile,
                }
            end
        end
    end
    return tiles
end

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
            { kind = "collect_color", color = "Leaf", targetCount = 8 },
            { kind = "collect_color", color = "Berry", targetCount = 6 },
        },
        starThresholds = { 1000, 2000, 3000 },
        coinReward = 50,
        starReward = 1,
    }

    -- 1. Game Session & Presentation State
    local session, setSession = React.useState(function()
        return BoardLogic.createSession(levelDef)
    end)

    local displayTiles, setDisplayTiles = React.useState(function()
        return createDisplayTilesFromGrid(session.grid, session.width, session.height)
    end)

    local displayedMoves, setDisplayedMoves = React.useState(session.movesRemaining)
    local displayedObjectives, setDisplayedObjectives = React.useState(session.objectives)
    local gameStatus, setGameStatus = React.useState("InProgress" :: GameStatus)
    local selectedCoord, setSelectedCoord = React.useState(nil :: Coord?)
    local isResolving, setIsResolving = React.useState(false)

    -- Request authoritative level start from server on mount
    React.useEffect(function()
        task.spawn(function()
            local serverRes = ClientNetwork.requestStartLevel(levelId)
            if serverRes and serverRes.success and serverRes.initialGrid then
                local s: BoardSession = {
                    width = serverRes.width,
                    height = serverRes.height,
                    grid = serverRes.initialGrid,
                    allowedColors = levelDef.allowedColors,
                    emptyCutouts = {},
                    movesRemaining = serverRes.moveLimit,
                    status = "InProgress" :: GameStatus,
                    objectives = serverRes.objectives,
                    rng = BoardLogic.createRNG(),
                    nextId = 64,
                }
                setSession(s)
                setDisplayTiles(createDisplayTilesFromGrid(s.grid, s.width, s.height))
                setDisplayedMoves(s.movesRemaining)
                setDisplayedObjectives(s.objectives)
            end
        end)
    end, { levelId })

    -- 2. Refs for Instances and Animation Overlay
    local tileRefs = React.useRef({} :: { [string]: GuiObject })
    local effectsOverlayRef = React.useRef(nil :: GuiObject?)

    local registerTileRef = React.useCallback(function(id: string, rbx: GuiObject?)
        if rbx then
            tileRefs.current[id] = rbx
        else
            tileRefs.current[id] = nil
        end
    end, {})

    -- Helper to find display tile by board coordinate
    local getDisplayTileAt = React.useCallback(function(coord: Coord, currentTiles: { [string]: DisplayTile }): DisplayTile?
        for _, dt in pairs(currentTiles) do
            if dt.coord.x == coord.x and dt.coord.y == coord.y then
                return dt
            end
        end
        return nil
    end, {})

    -- 3. Restart Handler
    local handleRestart = React.useCallback(function()
        -- Request server restart
        ClientNetwork.requestRestartLevel(levelId)

        local newSession = BoardLogic.createSession(levelDef)
        setSession(newSession)
        setDisplayTiles(createDisplayTilesFromGrid(newSession.grid, newSession.width, newSession.height))
        setDisplayedMoves(newSession.movesRemaining)
        setDisplayedObjectives(newSession.objectives)
        setSelectedCoord(nil)
        setIsResolving(false)
        setGameStatus("InProgress")
    end, { levelDef, levelId })

    -- 4. Move Execution and Cascade Coordinator
    local executeMove = React.useCallback(function(fromCoord: Coord, toCoord: Coord)
        setIsResolving(true)
        setSelectedCoord(nil)

        task.spawn(function()
            local tileA = getDisplayTileAt(fromCoord, displayTiles)
            local tileB = getDisplayTileAt(toCoord, displayTiles)

            local rbxA = if tileA then tileRefs.current[tileA.id] else nil
            local rbxB = if tileB then tileRefs.current[tileB.id] else nil

            -- Validate swap with pure engine
            local isValid = BoardLogic.validateSwap(session, fromCoord, toCoord)

            if not isValid then
                -- Play invalid swap rebound animation
                AnimationCoordinator.animateInvalidRebound(
                    rbxA,
                    fromCoord,
                    rbxB,
                    toCoord,
                    session.width,
                    session.height
                )
                -- Unlock input; moves remain unconsumed
                setIsResolving(false)
                return
            end

            -- Request server authoritative swap
            local serverResult = ClientNetwork.requestSwap(fromCoord, toCoord)
            if serverResult and not serverResult.valid then
                AnimationCoordinator.animateInvalidRebound(
                    rbxA,
                    fromCoord,
                    rbxB,
                    toCoord,
                    session.width,
                    session.height
                )
                setIsResolving(false)
                return
            end

            -- Valid swap: play adjacent tile swap tween
            AnimationCoordinator.animateSwap(
                rbxA,
                fromCoord,
                rbxB,
                toCoord,
                session.width,
                session.height
            )

            if serverResult and serverResult.approvedProfile and props.onProfileUpdated then
                props.onProfileUpdated(serverResult.approvedProfile)
            end

            -- If server returned cascade steps, use server's authoritative cascades; otherwise fallback to local BoardLogic
            local swapResult = if serverResult and serverResult.cascadeSteps
                then {
                    valid = true,
                    cascadeSteps = serverResult.cascadeSteps,
                    movesRemaining = serverResult.movesRemaining or (session.movesRemaining - 1),
                    reshuffled = serverResult.reshuffled,
                }
                else BoardLogic.executeSwap(session, fromCoord, toCoord)

            -- Deduct moves in presentation HUD
            local newMoves = if serverResult and serverResult.movesRemaining then serverResult.movesRemaining else (session.movesRemaining - 1)
            session.movesRemaining = newMoves
            setDisplayedMoves(newMoves)

            -- Swap positions in current display representation
            local workingTiles: { [string]: DisplayTile } = {}
            for id, dt in pairs(displayTiles) do
                workingTiles[id] = { id = dt.id, coord = BoardCoord.create(dt.coord.x, dt.coord.y), tile = dt.tile }
            end
            if tileA and tileB then
                workingTiles[tileA.id].coord = toCoord
                workingTiles[tileB.id].coord = fromCoord
            end

            -- Sequential Cascade Wave Playback
            if swapResult.cascadeSteps and #swapResult.cascadeSteps > 0 then
                for stepIndex, step in ipairs(swapResult.cascadeSteps) do
                    -- Step A: Pop matched tiles and bomb blast feedback
                    local popInstances: { GuiObject } = {}
                    for _, clearCoord in ipairs(step.clearedTiles) do
                        local t = getDisplayTileAt(clearCoord, workingTiles)
                        if t and tileRefs.current[t.id] then
                            table.insert(popInstances, tileRefs.current[t.id])
                        end
                        -- Check BlossomBomb detonation
                        if t and t.tile.special == "BlossomBomb" then
                            AnimationCoordinator.animateBombBlast(
                                effectsOverlayRef.current,
                                clearCoord,
                                session.width,
                                session.height
                            )
                        end
                    end

                    if #popInstances > 0 then
                        AnimationCoordinator.animatePopClear(popInstances)
                    end

                    -- Decrement displayed objectives incrementally for this wave
                    setDisplayedObjectives(function(prevObjs)
                        local updated = {}
                        for _, obj in ipairs(prevObjs) do
                            local copy = {
                                kind = obj.kind,
                                color = obj.color,
                                blocker = obj.blocker,
                                targetCount = obj.targetCount,
                                currentCount = obj.currentCount,
                                completed = obj.completed,
                            }
                            for _, clearCoord in ipairs(step.clearedTiles) do
                                local t = getDisplayTileAt(clearCoord, workingTiles)
                                if t and not copy.completed then
                                    if copy.kind == "collect_color" and copy.color == t.tile.color then
                                        copy.currentCount += 1
                                        if copy.currentCount >= copy.targetCount then
                                            copy.completed = true
                                        end
                                    elseif copy.kind == "clear_blocker" and copy.blocker == t.tile.blocker then
                                        copy.currentCount += 1
                                        if copy.currentCount >= copy.targetCount then
                                            copy.completed = true
                                        end
                                    end
                                end
                            end
                            table.insert(updated, copy)
                        end
                        return updated
                    end)

                    -- Remove cleared tiles from working set
                    for _, clearCoord in ipairs(step.clearedTiles) do
                        for id, dt in pairs(workingTiles) do
                            if dt.coord.x == clearCoord.x and dt.coord.y == clearCoord.y then
                                workingTiles[id] = nil
                                break
                            end
                        end
                    end

                    -- Insert newly spawned special pieces
                    for _, sp in ipairs(step.spawnedSpecials) do
                        local newSpecialTile: Tile = {
                            id = "sp_" .. sp.coord.x .. "_" .. sp.coord.y .. "_" .. stepIndex,
                            color = nil,
                            blocker = nil,
                            special = sp.specialType,
                            isMatched = false,
                        }
                        workingTiles[newSpecialTile.id] = {
                            id = newSpecialTile.id,
                            coord = sp.coord,
                            tile = newSpecialTile,
                        }
                    end

                    -- Step B: Gravity shifts and refill entry
                    local shiftList: { { instance: GuiObject, toCoord: Coord } } = {}
                    for _, shift in ipairs(step.shiftMoves) do
                        local t = getDisplayTileAt(shift.from, workingTiles)
                        if t then
                            t.coord = shift.to
                            local rbx = tileRefs.current[t.id]
                            if rbx then
                                table.insert(shiftList, { instance = rbx, toCoord = shift.to })
                            end
                        end
                    end

                    -- Top refills: add to working set and prepare entry drops
                    local refillList: { { instance: GuiObject, toCoord: Coord, startYOffset: number } } = {}
                    for _, refill in ipairs(step.refilledTiles) do
                        workingTiles[refill.tile.id] = {
                            id = refill.tile.id,
                            coord = refill.coord,
                            tile = refill.tile,
                        }
                    end

                    -- Update presentation state so new refill tiles mount into React
                    setDisplayTiles(table.clone(workingTiles))
                    task.wait() -- Allow React commit for new refill instances

                    for _, refill in ipairs(step.refilledTiles) do
                        local rbx = tileRefs.current[refill.tile.id]
                        if rbx then
                            table.insert(refillList, {
                                instance = rbx,
                                toCoord = refill.coord,
                                startYOffset = 2.5,
                            })
                        end
                    end

                    AnimationCoordinator.animateGravityAndRefills(
                        shiftList,
                        refillList,
                        session.width,
                        session.height
                    )

                    -- Stagger delay between cascade waves
                    if stepIndex < #swapResult.cascadeSteps then
                        task.wait(0.08)
                    end
                end
            end

            -- Final Settled Board Synchronization from authoritative server
            if serverResult and serverResult.finalGrid then
                session.grid = serverResult.finalGrid
            end
            if serverResult and serverResult.objectives then
                session.objectives = serverResult.objectives
            end
            if serverResult and serverResult.status then
                session.status = serverResult.status
            end

            setDisplayTiles(createDisplayTilesFromGrid(session.grid, session.width, session.height))
            setDisplayedObjectives(session.objectives)

            -- Reshuffle delay if triggered
            if swapResult.reshuffled then
                task.wait(0.35)
            end

            -- Evaluate Victory / Defeat ONLY after complete cascade resolution
            if session.status == "Won" then
                setGameStatus("Won")
            elseif session.status == "Lost" then
                setGameStatus("Lost")
            else
                -- Board settled, unlock input for next move
                setIsResolving(false)
            end
        end)
    end, { session, displayTiles, getDisplayTileAt, props.onProfileUpdated })

    -- 5. Tile Interaction Handler
    local handleTileClick = React.useCallback(function(coord: Coord)
        if isResolving then
            return -- Block touch while cascade / swap is active
        end
        if gameStatus ~= "InProgress" then
            return -- Block interaction after win or loss
        end

        if not selectedCoord then
            setSelectedCoord(coord)
        else
            if BoardCoord.equals(selectedCoord, coord) then
                setSelectedCoord(nil)
            elseif BoardCoord.isAdjacent(selectedCoord, coord) then
                executeMove(selectedCoord, coord)
            else
                setSelectedCoord(coord)
            end
        end
    end, { isResolving, gameStatus, selectedCoord, executeMove })

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
            movesRemaining = displayedMoves,
            objectives = displayedObjectives,
            status = gameStatus,
            onRestart = handleRestart,
            onReturnToMap = props.onReturnToMap,
        }),

        -- Centered 8x8 Board Container
        BoardArea = React.createElement("Frame", {
            Size = UDim2.new(1, 0, 0.65, 0),
            Position = UDim2.fromScale(0.5, 0.54),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
        }, {
            Grid = React.createElement(MatchGrid, {
                width = session.width,
                height = session.height,
                displayTiles = displayTiles,
                selectedCoord = selectedCoord,
                effectsOverlayRef = effectsOverlayRef,
                registerTileRef = registerTileRef,
                onTileClicked = handleTileClick,
            }),
        }),

        -- VICTORY CELEBRATION MODAL OVERLAY
        VictoryOverlay = (gameStatus == "Won") and React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.45,
            ZIndex = 50,
        }, {
            ModalCard = React.createElement("Frame", {
                Size = UDim2.new(0, 320, 0, 260),
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
                    Size = UDim2.new(1, 0, 0, 44),
                    Position = UDim2.new(0.5, 0, 0, 16),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = "LEVEL COMPLETE!",
                    Font = ThemeTokens.Typography.DisplayHero.Font,
                    TextSize = 24,
                    TextColor3 = ThemeTokens.Colors.CedarUmber,
                }),
                RewardText = React.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 32),
                    Position = UDim2.new(0.5, 0, 0, 64),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = "+1 STAR ⭐   +50 COINS 🪙",
                    Font = ThemeTokens.Typography.MetricValue.Font,
                    TextSize = 17,
                    TextColor3 = ThemeTokens.Colors.StarGold,
                }),
                
                -- Actions layout
                Actions = React.createElement("Frame", {
                    Size = UDim2.new(1, -32, 0, 100),
                    Position = UDim2.new(0.5, 0, 1, -16),
                    AnchorPoint = Vector2.new(0.5, 1),
                    BackgroundTransparency = 1,
                }, {
                    Layout = React.createElement("UIListLayout", {
                        FillDirection = Enum.FillDirection.Vertical,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, 10),
                    }),
                    -- Primary: Go to Garden restoration
                    GardenButton = React.createElement("TextButton", {
                        Size = UDim2.new(1, 0, 0, 44),
                        BackgroundColor3 = ThemeTokens.Colors.LeafSage,
                        Text = "RESTORE GARDEN 🌿",
                        Font = ThemeTokens.Typography.ButtonLabel.Font,
                        TextSize = 15,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        AutoButtonColor = true,
                        [React.Event.Activated] = function()
                            if props.onOpenGarden then
                                props.onOpenGarden()
                            elseif props.onReturnToMap then
                                props.onReturnToMap()
                            else
                                handleRestart()
                            end
                        end,
                    }, {
                        Corner = React.createElement("UICorner", { CornerRadius = ThemeTokens.Radii.Pill }),
                        Stroke = React.createElement("UIStroke", { Color = ThemeTokens.Colors.BotanicalForest, Thickness = 1.5 }),
                    }),
                    -- Secondary: Return to Map
                    MapButton = React.createElement("TextButton", {
                        Size = UDim2.new(1, 0, 0, 38),
                        BackgroundColor3 = ThemeTokens.Colors.RiverStone,
                        Text = "RETURN TO MAP 🌸",
                        Font = ThemeTokens.Typography.ButtonLabel.Font,
                        TextSize = 14,
                        TextColor3 = ThemeTokens.Colors.CedarUmber,
                        AutoButtonColor = true,
                        [React.Event.Activated] = function()
                            if props.onReturnToMap then
                                props.onReturnToMap()
                            else
                                handleRestart()
                            end
                        end,
                    }, {
                        Corner = React.createElement("UICorner", { CornerRadius = ThemeTokens.Radii.Pill }),
                        Stroke = React.createElement("UIStroke", { Color = ThemeTokens.Colors.CedarUmber, Thickness = 1.5 }),
                    }),
                }),
            }),
        }),

        -- DEFEAT / OUT OF MOVES MODAL OVERLAY
        DefeatOverlay = (gameStatus == "Lost") and React.createElement("Frame", {
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
                    Size = UDim2.new(1, 0, 0, 44),
                    Position = UDim2.new(0.5, 0, 0, 16),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = "OUT OF MOVES",
                    Font = ThemeTokens.Typography.DisplayHero.Font,
                    TextSize = 22,
                    TextColor3 = ThemeTokens.Colors.BerryCrimson,
                }),
                Desc = React.createElement("TextLabel", {
                    Size = UDim2.new(1, -32, 0, 32),
                    Position = UDim2.new(0.5, 0, 0, 60),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = "Don't worry! Try again to earn your garden star.",
                    Font = ThemeTokens.Typography.BodyText.Font,
                    TextSize = 13,
                    TextColor3 = ThemeTokens.Colors.CedarUmber,
                    TextWrapped = true,
                }),
                
                -- Actions: Retry & Return to Map
                DefeatActions = React.createElement("Frame", {
                    Size = UDim2.new(1, -32, 0, 96),
                    Position = UDim2.new(0.5, 0, 1, -16),
                    AnchorPoint = Vector2.new(0.5, 1),
                    BackgroundTransparency = 1,
                }, {
                    Layout = React.createElement("UIListLayout", {
                        FillDirection = Enum.FillDirection.Vertical,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, 8),
                    }),
                    RetryButton = React.createElement("TextButton", {
                        Size = UDim2.new(1, 0, 0, 42),
                        BackgroundColor3 = ThemeTokens.Colors.SproutLime,
                        Text = "RETRY",
                        Font = ThemeTokens.Typography.ButtonLabel.Font,
                        TextSize = 15,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        AutoButtonColor = true,
                        [React.Event.Activated] = handleRestart,
                    }, {
                        Corner = React.createElement("UICorner", { CornerRadius = ThemeTokens.Radii.Pill }),
                        Stroke = React.createElement("UIStroke", { Color = ThemeTokens.Colors.BotanicalForest, Thickness = 1.5 }),
                    }),
                    ReturnMapButton = React.createElement("TextButton", {
                        Size = UDim2.new(1, 0, 0, 36),
                        BackgroundColor3 = ThemeTokens.Colors.RiverStone,
                        Text = "RETURN TO MAP",
                        Font = ThemeTokens.Typography.ButtonLabel.Font,
                        TextSize = 13,
                        TextColor3 = ThemeTokens.Colors.CedarUmber,
                        AutoButtonColor = true,
                        [React.Event.Activated] = function()
                            if props.onReturnToMap then
                                props.onReturnToMap()
                            else
                                handleRestart()
                            end
                        end,
                    }, {
                        Corner = React.createElement("UICorner", { CornerRadius = ThemeTokens.Radii.Pill }),
                        Stroke = React.createElement("UIStroke", { Color = ThemeTokens.Colors.CedarUmber, Thickness = 1.5 }),
                    }),
                }),
            }),
        }),
    })
end

return PuzzleScreen
