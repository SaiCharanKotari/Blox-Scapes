--!strict
-- demo_cascade.luau: Deterministic demonstration of a known fixed board resolving matches, gravity, and cascades
-- Strict adherence to single-swap cell invariance: only the 2 swapped cells differ immediately after swap.

local BoardTypes = require("../src/shared/Types/BoardTypes")
local LevelTypes = require("../src/shared/Types/LevelTypes")
local BoardCoord = require("../src/shared/Utils/BoardCoord")
local MatchDetector = require("../src/shared/Puzzle/MatchDetector")
local GravityResolver = require("../src/shared/Puzzle/GravityResolver")
local BoardLogic = require("../src/shared/Puzzle/BoardLogic")

type Coord = BoardTypes.Coord
type Tile = BoardTypes.Tile
type Grid = BoardTypes.Grid
type TileColor = BoardTypes.TileColor

local EMOJI_MAP: { [TileColor]: string } = {
    Berry = "🍎",
    Leaf = "🍃",
    Blossom = "🌻",
    Dewdrop = "💧",
    Plum = "🍇",
}

local function formatTile(tile: Tile?): string
    if not tile then
        return " .  "
    end
    if tile.special == "BlossomBomb" then
        return "BOMB"
    end
    if tile.color and EMOJI_MAP[tile.color] then
        return EMOJI_MAP[tile.color] .. "  "
    end
    return " ?  "
end

local function printGrid(grid: Grid, width: number, height: number, label: string)
    print(string.format("\n--- %s ---", label))
    for y = 1, height do
        local line = ""
        for x = 1, width do
            local tile = BoardCoord.getTile(grid, x, y)
            line ..= formatTile(tile) .. " "
        end
        print(string.format("Row %d: %s", y, line))
    end
end

-- 1. Create a 100% fixed, explicit 6x6 board layout with ZERO initial matches
-- Board layout designed so swapping (3, 4) Leaf with (4, 4) Berry creates a 3-Berry match on Row 4!
--
-- Row 1: 💧  🍃  🌻  💧  🍃  🌻
-- Row 2: 🍃  🌻  💧  🍃  🌻  💧
-- Row 3: 🌻  💧  🍃  🌻  💧  🍃
-- Row 4: 🍎  🍎  🍃  🍎  🌻  💧   <-- Swap (3,4) Leaf with (4,4) Berry -> 🍎 🍎 🍎 🍃 🌻 💧
-- Row 5: 💧  🍃  🌻  💧  🍃  🌻
-- Row 6: 🍃  🌻  💧  🍃  🌻  💧

local FIXED_COLORS: { { TileColor } } = {
    { "Dewdrop", "Leaf",    "Blossom", "Dewdrop", "Leaf",    "Blossom" }, -- Row 1
    { "Leaf",    "Blossom", "Dewdrop", "Leaf",    "Blossom", "Dewdrop" }, -- Row 2
    { "Blossom", "Dewdrop", "Leaf",    "Blossom", "Dewdrop", "Leaf"    }, -- Row 3
    { "Berry",   "Berry",   "Leaf",    "Berry",   "Blossom", "Dewdrop" }, -- Row 4
    { "Dewdrop", "Leaf",    "Blossom", "Dewdrop", "Leaf",    "Blossom" }, -- Row 5
    { "Leaf",    "Blossom", "Dewdrop", "Leaf",    "Blossom", "Dewdrop" }, -- Row 6
}

local width = 6
local height = 6
local levelDef: LevelTypes.LevelDefinition = {
    id = 1,
    title = "Deterministic Cascade Fixture",
    width = width,
    height = height,
    moveLimit = 15,
    allowedColors = { "Berry", "Leaf", "Blossom", "Dewdrop" },
    objectives = {
        { kind = "collect_color", color = "Berry", targetCount = 3 },
    },
    starThresholds = { 500, 1000, 1500 },
    coinReward = 50,
    starReward = 1,
}

-- Initialize session with deterministic seed
local session = BoardLogic.createSession(levelDef, 42)

-- Populate session with the fixed color matrix
local tileCounter = 0
for y = 1, height do
    for x = 1, width do
        tileCounter += 1
        local tile: Tile = {
            id = "fixed_" .. tileCounter,
            color = FIXED_COLORS[y][x],
            blocker = nil,
            special = nil,
            isMatched = false,
        }
        BoardCoord.setTile(session.grid, x, y, tile)
    end
end

-- Verify initial board has NO matches
local initialMatches = MatchDetector.findMatches(session.grid, width, height)
assert(#initialMatches == 0, "Initial fixed board must have 0 matches")

print("=================================================================")
print("  BLOOMTRAIL: DETERMINISTIC CASCADE DEMONSTRATION")
print("=================================================================")

printGrid(session.grid, width, height, "1. FIXED BOARD BEFORE SWAP")

local fromCoord = BoardCoord.create(3, 4) -- Row 4, Col 3: Leaf
local toCoord = BoardCoord.create(4, 4)   -- Row 4, Col 4: Berry

local tileFromBefore = BoardCoord.getTile(session.grid, fromCoord.x, fromCoord.y)
local tileToBefore = BoardCoord.getTile(session.grid, toCoord.x, toCoord.y)

assert(tileFromBefore and tileFromBefore.color == "Leaf", "From tile must be Leaf")
assert(tileToBefore and tileToBefore.color == "Berry", "To tile must be Berry")
assert(BoardCoord.isAdjacent(fromCoord, toCoord), "Swap cells must be strictly adjacent")

print(string.format("\nTarget Swap: Cell (%d, %d) [%s] <--> Cell (%d, %d) [%s]",
    fromCoord.x, fromCoord.y, tileFromBefore.color,
    toCoord.x, toCoord.y, tileToBefore.color))

-- Take full snapshot of the board before swap to verify cell invariance
local preSwapSnapshot = BoardCoord.cloneGrid(session.grid, width, height)

-- 2. Execute the swap and capture the state immediately after the swap
-- We manually execute the single swap on the grid and inspect it
BoardCoord.setTile(session.grid, fromCoord.x, fromCoord.y, tileToBefore)
BoardCoord.setTile(session.grid, toCoord.x, toCoord.y, tileFromBefore)

printGrid(session.grid, width, height, "2. BOARD IMMEDIATELY AFTER SWAP (Pre-Cascade)")

-- Verify cell invariance: exactly 2 cells changed, all 34 other cells are identical
local changedCells = 0
for y = 1, height do
    for x = 1, width do
        local orig = BoardCoord.getTile(preSwapSnapshot, x, y)
        local curr = BoardCoord.getTile(session.grid, x, y)
        if orig and curr and orig.color ~= curr.color then
            changedCells += 1
            print(string.format("  Verified Changed Cell: (%d, %d) was %s, now %s", x, y, orig.color, curr.color))
        end
    end
end
assert(changedCells == 2, "Assertion Failed: Exactly 2 cells must change immediately after swap")
print(string.format("  Cell Invariance Verified: Exactly %d / %d cells modified.", changedCells, width * height))

-- Revert the test swap on session grid so we can run the engine's executeSwap cleanly
BoardCoord.setTile(session.grid, fromCoord.x, fromCoord.y, tileFromBefore)
BoardCoord.setTile(session.grid, toCoord.x, toCoord.y, tileToBefore)

-- 3. Execute authoritative swap through the engine
local initialMoves = session.movesRemaining
local result = BoardLogic.executeSwap(session, fromCoord, toCoord)

assert(result.valid == true, "Swap must be valid")
assert(session.movesRemaining == initialMoves - 1, "Move count must decrement by exactly 1")
assert(result.matchGroups and #result.matchGroups > 0, "Matches must be found")

print("\n--- 3. SWAP RESOLUTION & CASCADE TRACE ---")
print(string.format("Swap Status: VALID | Moves Remaining: %d (Decremented from %d)", session.movesRemaining, initialMoves))
print(string.format("Initial Matches: %d match group(s)", #result.matchGroups))

for i, group in ipairs(result.matchGroups) do
    local coordList = ""
    for _, c in ipairs(group.coords) do
        coordList ..= string.format("(%d,%d) ", c.x, c.y)
    end
    print(string.format("  Match %d: Color = %s | Count = %d tiles | Coords = [ %s]", 
        i, group.color, #group.coords, coordList))
end

assert(result.cascadeSteps ~= nil, "Cascade steps must be recorded")
print(string.format("\nCascade Chain: %d wave(s) resolved to stability", #result.cascadeSteps))

for waveIndex, step in ipairs(result.cascadeSteps) do
    print(string.format("  Wave %d: Cleared %d tiles | Shifted %d tiles down | Refilled %d new tiles",
        waveIndex, #step.clearedTiles, #step.shiftMoves, #step.refilledTiles))
end

printGrid(session.grid, width, height, "4. FINAL STABLE BOARD (Post-Cascades & Refill)")

-- 4. Verify post-conditions on the final board
local postMatches = MatchDetector.findMatches(session.grid, width, height)
assert(#postMatches == 0, "Assertion Failed: Final board must contain 0 unresolved matches")

local berryObj = session.objectives[1]
print("\n--- 5. GAME OBJECTIVES & WIN EVALUATION ---")
print(string.format("Objective: Collect Berry [%d / %d] | Completed: %s",
    berryObj.currentCount, berryObj.targetCount, tostring(berryObj.completed)))
print(string.format("Game Session Status: %s", session.status))

assert(berryObj.completed == true, "Berry objective must be satisfied")
assert(session.status == "Won", "Game must evaluate to Won")

print("\nAll deterministic assertions passed. Cascade demonstration is 100% verified.")
