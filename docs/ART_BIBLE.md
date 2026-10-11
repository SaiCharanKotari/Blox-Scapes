# Project Bloomtrail — Art Bible & Visual Design System

**Document Version:** 2.0  
**Phase:** Gate 0 Audit & Gate 1 Design Specification  
**Visual Style Target:** Storybook Illustrated Botanical Garden with Tactile Casual Puzzle Pieces  
**UI Paradigm:** Declarative React-Lua Component System with Centralized Design Tokens  
**Primary Layout:** Mobile Portrait Baseline (9:16 aspect: 390 x 844 pt / 720 x 1280 pt) with Tablet and PC Adaptations  

---

## 1. Visual Direction & Aesthetic Philosophy

Project Bloomtrail evokes the timeless warmth and charm of a hand-illustrated botanical storybook combined with the tactile clarity and punchy physical feedback of premier modern casual puzzle games.

### Core Visual Pillars
1. **Tactile Storybook Craftsmanship:** Interfaces avoid flat, cold vector squares or generic Roblox templates. Surfaces feel authored from warm parchment, carved cedar wood, etched limestone, and glowing floral rosettes.
2. **Clear Dual-Coded Readability:** In match-3 gameplay, fast readability is paramount. Every puzzle piece features a unique, distinct silhouette **and** a rich, harmonious color token. Players never have to squint or rely solely on color recognition.
3. **Harmonious Botanical Palette:** Colors are curated, soft, and warm. Raw neons, arbitrary rainbow gradients, and generic emoji are strictly prohibited.
4. **Living 3D Courtyard World:** The garden restoration space uses warm, golden-hour directional lighting, gentle foliage wind flutter, sparkling fountain water particles, and tangible before-and-after visual transformations.

---

## 2. Visual Concept References (Screen Mockups)

Four high-fidelity visual concepts establish the aesthetic standard for Project Bloomtrail:

| Concept Concept | Reference File | Key Visual Mechanics Shown |
|---|---|---|
| **World Progression Map** | [bloomtrail_world_map.jpg](file:///c:/Users/saich/Desktop/GardenScapes/docs/concepts/bloomtrail_world_map.jpg) | Vertically scrolling stone path, carved level nodes, 3-star sockets, radiant active node, brass locked nodes, parchment HUD, "Play Next" pill button. |
| **Match-3 Puzzle Board** | [bloomtrail_puzzle_screen.jpg](file:///c:/Users/saich/Desktop/GardenScapes/docs/concepts/bloomtrail_puzzle_screen.jpg) | Centered 8x8 carved cedar wood frame, tactile dual-coded pieces, swap feedback particles, moves counter, objective goal cards, bottom booster drawer. |
| **Garden Restoration Courtyard** | [bloomtrail_garden_restoration.jpg](file:///c:/Users/saich/Desktop/GardenScapes/docs/concepts/bloomtrail_garden_restoration.jpg) | Overgrown limestone fountain transitioning to pristine flowing water, blooming flowerbeds, star/coin counters, "Restore Fountain Basin" task card. |
| **UI Kit & Design System** | [bloomtrail_design_system_kit.jpg](file:///c:/Users/saich/Desktop/GardenScapes/docs/concepts/bloomtrail_design_system_kit.jpg) | Full color swatches, piece tokens, button interaction states (Normal, Hover, Pressed), carved dialog frames, star and coin reward icons. |

---

## 3. Comprehensive Design Tokens

### 3.1 Color Palette & Semantic Roles

```
SURFACES & CONTAINERS
├── Parchment Warm Ivory   : #FFF8EE (RGB: 255, 248, 238) | Color3.fromRGB(255, 248, 238) - Dialog bodies, cards
├── Pale River Stone       : #E8E0D5 (RGB: 232, 224, 213) | Color3.fromRGB(232, 224, 213) - Locked nodes, borders
├── Carved Cedar Umber     : #5C381E (RGB:  92,  56,  30) | Color3.fromRGB( 92,  56,  30) - Primary frames & timber
├── Deep Espresso Shadow   : #2E1B0E (RGB:  46,  27,  14) | Color3.fromRGB( 46,  27,  14) - Outer strokes & shadows
└── Botanical Scrim Dark   : #142314 (RGB:  20,  35,  20) | Color3.fromRGB( 20,  35,  20) - Modal backdrops (Transp: 0.45)

BOTANICAL ACCENTS
├── Leafy Sage Green       : #4E8D53 (RGB:  78, 141,  83) | Color3.fromRGB( 78, 141,  83) - Action buttons, leaf tiles
├── Deep Botanical Forest  : #264D2B (RGB:  38,  77,  43) | Color3.fromRGB( 38,  77,  43) - Dark bevels, Ivy blocker
└── Sunlit Sprout Lime     : #8AC926 (RGB: 138, 201,  38) | Color3.fromRGB(138, 201,  38) - Button highlight gradient top

MATCH-3 PUZZLE PIECE TOKENS
├── Berry Crimson (Red)    : #E63946 (RGB: 230,  57,  70) | Color3.fromRGB(230,  57,  70) - Heart-tapered wild berry
├── Sky Dewdrop (Blue)     : #2A9D8F (RGB:  42, 157, 143) | Color3.fromRGB( 42, 157, 143) - Tear-shaped translucent drop
├── Sun Blossom (Yellow)   : #F4A261 (RGB: 244, 162,  97) | Color3.fromRGB(244, 162,  97) - 8-petal radial sunflower
├── Royal Plum (Purple)    : #7209B7 (RGB: 114,   9, 183) | Color3.fromRGB(114,   9, 183) - Matte velvet plum
├── Emerald Leaf (Green)   : #4E8D53 (RGB:  78, 141,  83) | Color3.fromRGB( 78, 141,  83) - Pointed ovate leaf gem
├── Ivy Blocker (Vine)     : #264D2B (RGB:  38,  77,  43) | Color3.fromRGB( 38,  77,  43) - Coiled thorn vine overlay
└── Blossom Bomb (Rainbow) : Prismatic Multi-hue Aura     | Multi-stop color sequence   - 4-in-a-row special piece

METRICS & REWARD TOKENS
├── Radiant Star Gold      : #FFB703 (RGB: 255, 183,   3) | Color3.fromRGB(255, 183,   3) - Stars, level glows
└── Sunlit Coin Amber      : #FB8500 (RGB: 251, 133,   0) | Color3.fromRGB(251, 133,   0) - Currency badges & coins
```

### 3.2 Spacing & Layout Scale
All layout margins, paddings, and gaps follow an intentional 4-point harmonic scale:

| Token | Pixels (Pt) | Primary Usage |
|---|---|---|
| `space.xxs` | 4 pt | Inner icon-to-label gaps, border bevel thickness |
| `space.xs` | 8 pt | Tile grid slot padding, micro-badge padding |
| `space.sm` | 12 pt | Internal card padding, goal badge margins |
| `space.md` | 16 pt | Screen container horizontal padding, modal interior margins |
| `space.lg` | 24 pt | Section separators, HUD top spacing |
| `space.xl` | 32 pt | Modal header spacing, bottom navigation height allowance |
| `space.xxl`| 48 pt | Screen title hero margins, map landmark pacing |

### 3.3 Typography Hierarchy & Roblox Font Mappings

| Role | Roblox Enum Font | Size (Mobile Pt) | Size (Tablet/PC) | Color Token | Drop Shadow Offset & Color |
|---|---|---|---|---|---|
| **Display Hero** | `Enum.Font.FredokaOne` | 34 pt | 44 pt | Parchment Ivory `#FFF8EE` | `(0, 3)` @ `#2E1B0E` (100% opacity) |
| **Section Header** | `Enum.Font.GothamBold` | 24 pt | 30 pt | Cedar Umber `#5C381E` | None |
| **Metric Value (Moves)**| `Enum.Font.GothamBlack`| 28 pt | 36 pt | Star Gold `#FFB703` | `(0, 2)` @ `#2E1B0E` |
| **Card / Button Title**| `Enum.Font.GothamBold` | 18 pt | 22 pt | Parchment Ivory `#FFF8EE` | `(0, 1.5)` @ `#264D2B` |
| **Body / Description** | `Enum.Font.GothamMedium`| 14 pt | 16 pt | Cedar Umber `#4A3728` | None |
| **Micro Caption** | `Enum.Font.Gotham` | 11 pt | 13 pt | Muted Umber `#765C48` | None |

### 3.4 Corner Radii & Geometry
- **Pill Buttons (`ui_button_primary_pill`):** `UDim.new(0.5, 0)` (Full capsule).
- **Modal Dialog Frames (`ui_frame_timber_modal`):** `UDim.new(0, 18)` with carved corner rosettes.
- **Goal Cards / HUD Capsules:** `UDim.new(0, 12)` with 2px stroke bevel.
- **Puzzle Tiles:** `UDim.new(0, 10)` with smooth specular rim.
- **Level Medallions:** `UDim.new(1.0, 0)` (Perfect circular stepping stone).

---

## 4. Iconography & Puzzle Piece Silhouettes

Strict adherence to **Dual-Coding**: Every piece must be immediately identifiable by silhouette alone in pure grayscale.

```
+-----------------------------------------------------------------------------------+
| TILE IDENTIFIER   | COLOR TOKEN   | SILHOUETTE GEOMETRY         | TEXTURE FINISH |
+-----------------------------------------------------------------------------------+
| Apple Berry       | Crimson #E639 | Rounded heart with leaf top | Glossy enamel  |
| Emerald Leaf      | Sage #4E8D    | Pointed ovate with rib vein | Translucent gem|
| Sun Blossom       | Yellow #F4A2  | 8 rounded petals + disc     | Velvet floral  |
| Water Dewdrop     | Aqua #2A9D    | Teardrop with sharp apex    | Specular glass |
| Royal Plum        | Purple #7209  | Symmetrical oval with cleft | Matte satin    |
| Blossom Bomb      | Multi-Color   | 6-petal rotating flower bud | Radiant aura   |
| Ivy Blocker       | Forest #264D  | Interlocking vine brambles  | Weathered bark |
+-----------------------------------------------------------------------------------+
```

---

## 5. UI Component Hierarchy & Interaction States

### 5.1 Primary Pill Button (`<PillButton />`)
- **Structure:** 3-layer composition:
  1. *Bottom Bevel Rim:* Deep Botanical Forest (`#264D2B`), 4pt height offset.
  2. *Face Gradient:* Vertical gradient from Sunlit Sprout Lime (`#8AC926`, top) to Leafy Sage Green (`#4E8D53`, bottom).
  3. *Inner Highlight Rim:* 1.5pt white-to-transparent inset border stroke.
- **State Behaviors:**
  - `Normal`: Scale `1.0`, Y-offset `0px`.
  - `Hover` (Desktop / Pointer): Scale `1.03`, gradient brightness +8%, cursor `Point`.
  - `Pressed` (Touch / Click): Scale `0.96`, Y-offset `+4px` (visually flattens bottom bevel rim), duration `0.08s` Quad-Out.
  - `Disabled`: Saturation `0.35`, brightness `0.70`, no hover scale, bevel flattened.

### 5.2 Progression Level Node (`<LevelNode />`)
- **Completed Node:** Carved round wooden disc (`#5C381E`), stamped level number in cream, 3 golden stars arched below node.
- **Active / Unlocked Node:** Slightly elevated wooden disc (scale 1.1) surrounded by a soft pulsating golden particle aura (`#FFB703`, 1.5s loop), bouncing "PLAY" arrow overhead.
- **Locked Node:** Weathered pale river stone disc (`#E8E0D5`), stamped iron number, locked brass padlock overlay with chain accents. Tapping triggers a gentle shake animation (`±4px` X-axis).

### 5.3 Goal Card (`<GoalBadge />`)
- Hanging parchment tag with twine loop graphic at top.
- Left: Tile silhouette thumbnail with count overlay.
- Right: Target counter (e.g., `15`). Decrements in real-time with a satisfying green flash and bump-scale (`1.0 -> 1.25 -> 1.0`).
- Completed Goal: Counter replaced with a radiant green checkmark badge (`#8AC926`).

---

## 6. Animation & Motion Choreography

All motion parameters are standardized to guarantee a snappy, tactile feel without sluggishness:

```luau
-- Timing and easing constants for UI and board animations
local MotionTokens = {
    TileSwapDuration = 0.18,          -- Quad Out
    FailedSwapDuration = 0.22,        -- Sine InOut (rebound)
    TilePopClearDuration = 0.20,      -- Back In (scale up 1.25 then shrink to 0)
    GravityDropDuration = 0.26,       -- Bounce Out (settling tiles)
    CascadeChainDelay = 0.08,         -- Stagger between cascade waves
    ModalEntranceDuration = 0.32,     -- Back Out (overshoot scale 1.05 -> 1.0)
    StarArcFlightDuration = 0.65,     -- Cubic InOut (Bezier arc to HUD)
    ButtonPressDuration = 0.08,       -- Quad Out
}
```

---

## 7. 3D Garden Environment Materials & Lighting

### 7.1 Lighting Configuration (Roblox `Lighting` Service)
- **Technology:** `Enum.Technology.Future` (or `ShadowMap` fallback for low-end mobile).
- **TimeOfDay:** `08:30:00` (Warm morning golden hour).
- **ClockRayleigh / Sky:** Gentle blue sky with soft cumulus clouds.
- **ColorCorrection:**
  - `Brightness`: `0.02`
  - `Contrast`: `0.08`
  - `Saturation`: `0.15` (Warm, lush, saturated botanical vibrancy)
  - `TintColor`: `Color3.fromRGB(255, 250, 240)`
- **Atmosphere:**
  - `Density`: `0.30`
  - `Offset`: `0.25`
  - `Color`: `Color3.fromRGB(220, 235, 215)`
  - `Glare`: `0.1`
  - `Haze`: `0.2`

### 7.2 Garden Transformation States (Area 1: Courtyard Fountain)
- **Stage 0 (Overgrown / Abandoned):**
  - Fountain basin: Weathered cracked limestone (`Material.Limestone`), dry cracked earth inside, thick ivy vines wrapping around tiers.
  - Surrounding beds: Unruly dry weeds, stray cobblestones, dead branches.
- **Stage 1 (Clean Basin — Task 1):**
  - Vines dissolved via green leaf particle burst; cracked textures swapped for clean carved limestone.
- **Stage 2 (Restore Water Pipes — Task 2):**
  - Brass plumbing fixtures installed; crystal-clear water fills basin with animated fountain spray particles and water ripple mesh.
- **Stage 3 (Courtyard Flowerbeds — Task 3):**
  - Lush pink hydrangeas and white roses sprout up around perimeter with golden sparkle burst.

---

## 8. Safe Areas & Responsive Viewport Rules

The UI layout is engineered with portrait-first ergonomics and fluid adaptations for tablet and PC:

### 8.1 Mobile Portrait (Baseline: 9:16 / 19.5:9 Notch Devices)
- **Top Safe Margin:** Reserve top `44 pt` (Dynamic Island / camera notch) + `32 pt` Roblox Topbar. Total header inset: `76 pt`.
- **Bottom Safe Margin:** Reserve bottom `34 pt` (Home indicator bar).
- **Board Container:** Centered vertically between HUD and bottom drawers. Dynamic tile size formula:
  $$\text{TileSize} = \min\left(\frac{\text{ViewportWidth} \times 0.92}{8}, \frac{\text{ViewportHeight} \times 0.55}{8}\right)$$
- **Touch Target Minimum:** All buttons, nodes, and tiles have an active hit target $\ge 44 \times 44\text{ pt}$.

### 8.2 Tablet & PC Adaptations (4:3, 16:9 Landscape)
- On tablet / PC widescreen, the gameplay board remains centered with maximum dimensions capped at $540 \times 540\text{ pt}$ to prevent absurd stretching.
- HUD components gracefully expand outward to the left and right flanks (Goal cards on the left, moves counter on top, boosters on the right), framing the board elegantly.

---

## 9. React-Lua Component System Integration

To fulfill the user's architectural choice, all UI screens are structured as declarative React-Lua components.

### 9.1 Component Structure
```
src/client/UI/
├── Contexts/
│   └── ThemeContext.luau          -- Provides Design Tokens to all subtrees
├── Components/
│   ├── Common/
│   │   ├── PillButton.luau        -- Reusable styled button with state tweens
│   │   ├── ModalFrame.luau        -- Timber & ivory frame container
│   │   └── ResourceBadge.luau     -- Star and Coin HUD counters
│   ├── Map/
│   │   ├── WorldMapView.luau      -- Scrolling trail container
│   │   ├── LevelNode.luau         -- Completed, active, and locked nodes
│   │   └── MapBottomNav.luau      -- Bottom navigation dock
│   ├── Puzzle/
│   │   ├── PuzzleScreen.luau      -- Top HUD, grid container, and booster drawer
│   │   ├── MatchGrid.luau         -- 8x8 Board layout
│   │   ├── TileComponent.luau     -- Dual-coded interactive tile with swap animation
│   │   └── GoalDrawer.luau        -- Live objective tracking drawer
│   └── Garden/
│       ├── GardenScreen.luau      -- Viewport camera overlay
│       └── TaskDrawer.luau        -- Active task card with before/after preview
```

### 9.2 Token Usage Pattern in React-Lua
```luau
local React = require(ReplicatedStorage.BloomtrailShared.Packages.React)
local Theme = require(ReplicatedStorage.BloomtrailShared.Config.ThemeTokens)

local function PillButton(props: {
    text: string,
    onActivated: () -> (),
    isDisabled: boolean?,
})
    return React.createElement("TextButton", {
        Size = UDim2.new(0, 200, 0, 52),
        BackgroundColor3 = Theme.Colors.LeafSage,
        AutoButtonColor = false,
        [React.Event.Activated] = props.onActivated,
    }, {
        Corner = React.createElement("UICorner", {
            CornerRadius = Theme.Radii.Pill,
        }),
        Gradient = React.createElement("UIGradient", {
            Color = ColorSequence.new(Theme.Colors.SproutLime, Theme.Colors.LeafSage),
            Rotation = 90,
        }),
        Label = React.createElement("TextLabel", {
            Text = props.text,
            Font = Theme.Typography.DisplayTitle.Font,
            TextSize = Theme.Typography.DisplayTitle.Size,
            TextColor3 = Theme.Colors.ParchmentIvory,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
        })
    })
end

return PillButton
```

---

## 10. Visual Quality Gate Checklist

Before approving any newly added asset, model, or screen:

- [ ] **Dual-Coding Check:** Are tiles identifiable in grayscale without color?
- [ ] **Token Compliance:** Are all colors, margins, and fonts sourced from `ThemeTokens.luau`?
- [ ] **Tactile Feedback:** Do buttons exhibit visible pressed depth and sound triggers?
- [ ] **Touch Target Safety:** Is every tappable element at least $44 \times 44\text{ pt}$?
- [ ] **Safe-Area Compliance:** Does the screen maintain safe insets on notched mobile devices?
- [ ] **Originality Guardrail:** Are all character styles, logos, and layouts strictly original?
