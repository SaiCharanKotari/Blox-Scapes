# Project Bloomtrail — Level Schema & Sample Level Configurations

**Document Version:** 1.0  
**Phase:** Gate 0 (Pre-Production)  
**Standard Grid:** 8 x 8 Tiles (Dynamic width/height supported)  

---

## 1. Data-Driven Level Schema Specification

Levels in Project Bloomtrail are pure declarative data dictionaries. Level definitions contain zero executable code or hardcoded logic, making them easily authorable, modifiable, and testable.

### Luau Type Specification (`LevelTypes.luau`)

```luau
--!strict

export type TileColor = "Berry" | "Leaf" | "Blossom" | "Dewdrop" | "Plum"
export type BlockerType = "Ivy" | "Stone"
export type SpecialPieceType = "BlossomBomb" | "LineClearHorizontal" | "LineClearVertical"

export type ObjectiveType = 
    | { kind: "collect_color", color: TileColor, targetCount: number }
    | { kind: "clear_blocker", blocker: BlockerType, targetCount: number }
    | { kind: "reach_score", targetScore: number }

export type PreplacedTile = {
    x: number,
    y: number,
    tileType: "color" | "blocker" | "empty",
    color: TileColor?,
    blocker: BlockerType?,
}

export type LevelDefinition = {
    id: number,
    title: string,
    width: number,                       -- Standard: 8
    height: number,                      -- Standard: 8
    moveLimit: number,                   -- Move budget for the player
    allowedColors: { TileColor },        -- Palette pool used for refills
    objectives: { ObjectiveType },       -- Array of victory requirements
    starThresholds: { number },          -- [1-Star, 2-Star, 3-Star] score targets
    preplacedGrid: { PreplacedTile }?,   -- Optional manual slot overrides
    coinReward: number,                  -- Standard win reward: 50 coins
    starReward: number,                  -- Standard win reward: 1 star
}
```

---

## 2. Concrete Sample Level Definitions

### Level 1: "First Blooms" (Introduction & Basic Matches)
- **Design Intent:** Teach players tap-to-swap mechanics and clear visual color feedback with a very forgiving move count and 4 vibrant colors.
- **Grid Layout:** Standard 8x8, no holes, no blockers.
- **Move Limit:** 25 moves.
- **Allowed Colors:** Berry (Red), Leaf (Green), Blossom (Yellow), Dewdrop (Blue).
- **Objectives:**
  1. Collect 15 `Leaf` tiles.
  2. Collect 10 `Berry` tiles.
- **Rewards:** 1 Star, 50 Coins.

```luau
local Level1: LevelDefinition = {
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
```

---

### Level 2: "Tangled Vines" (Introducing Obstacles / Blockers)
- **Design Intent:** Introduces the `Ivy` blocker. Ivy coils around tiles in the bottom rows. Making an adjacent match clears the ivy.
- **Grid Layout:** 8x8 with 8 Ivy blockers pre-placed across row 7 and row 8.
- **Move Limit:** 22 moves.
- **Allowed Colors:** Berry, Leaf, Blossom, Dewdrop, Plum (5 colors).
- **Objectives:**
  1. Clear 8 `Ivy` blockers.
  2. Collect 12 `Dewdrop` tiles.
- **Rewards:** 1 Star, 50 Coins.

```luau
local Level2: LevelDefinition = {
    id = 2,
    title = "Tangled Vines",
    width = 8,
    height = 8,
    moveLimit = 22,
    allowedColors = { "Berry", "Leaf", "Blossom", "Dewdrop", "Plum" },
    objectives = {
        { kind = "clear_blocker", blocker = "Ivy", targetCount = 8 },
        { kind = "collect_color", color = "Dewdrop", targetCount = 12 },
    },
    starThresholds = { 1200, 2400, 3600 },
    preplacedGrid = {
        { x = 1, y = 7, tileType = "blocker", blocker = "Ivy" },
        { x = 2, y = 7, tileType = "blocker", blocker = "Ivy" },
        { x = 7, y = 7, tileType = "blocker", blocker = "Ivy" },
        { x = 8, y = 7, tileType = "blocker", blocker = "Ivy" },
        { x = 3, y = 8, tileType = "blocker", blocker = "Ivy" },
        { x = 4, y = 8, tileType = "blocker", blocker = "Ivy" },
        { x = 5, y = 8, tileType = "blocker", blocker = "Ivy" },
        { x = 6, y = 8, tileType = "blocker", blocker = "Ivy" },
    },
    coinReward = 50,
    starReward = 1,
}
```

---

### Level 3: "Sunlit Clearing" (Special Pieces & Combo Creation)
- **Design Intent:** Teaches players how matching 4 tiles in a line spawns a `BlossomBomb` special piece that explodes adjacent tiles in a 3x3 radius.
- **Grid Layout:** 8x8 with irregular corner cutouts (corners `(1,1), (1,8), (8,1), (8,8)` are empty slots).
- **Move Limit:** 20 moves.
- **Allowed Colors:** Berry, Leaf, Blossom, Dewdrop, Plum.
- **Objectives:**
  1. Collect 20 `Blossom` tiles.
  2. Collect 15 `Plum` tiles.
- **Rewards:** 1 Star, 50 Coins.

```luau
local Level3: LevelDefinition = {
    id = 3,
    title = "Sunlit Clearing",
    width = 8,
    height = 8,
    moveLimit = 20,
    allowedColors = { "Berry", "Leaf", "Blossom", "Dewdrop", "Plum" },
    objectives = {
        { kind = "collect_color", color = "Blossom", targetCount = 20 },
        { kind = "collect_color", color = "Plum", targetCount = 15 },
    },
    starThresholds = { 1500, 3000, 4500 },
    preplacedGrid = {
        { x = 1, y = 1, tileType = "empty" },
        { x = 8, y = 1, tileType = "empty" },
        { x = 1, y = 8, tileType = "empty" },
        { x = 8, y = 8, tileType = "empty" },
    },
    coinReward = 50,
    starReward = 1,
}
```
