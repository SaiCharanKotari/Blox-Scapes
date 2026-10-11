# Project Bloomtrail — Asset Production Manifest

**Document Version:** 1.0  
**Phase:** Gate 0 (Pre-Production)  
**Licensing Standard:** All assets must be original, public domain CC0, or created within Roblox terms. No copyrighted assets from third-party IP.

---

## 1. 2D UI Sprites & Vector Graphic Elements

| Asset Identifier | Dimensions | Aspect Ratio | Category | Purpose / Screen | Status | Source / Note |
|---|---|---|---|---|---|---|
| `tile_berry_crimson` | 256 x 256 px | 1:1 | Puzzle Tile | Apple/Berry match-3 standard piece | Concept (Mockup) | Original creation |
| `tile_leaf_sage` | 256 x 256 px | 1:1 | Puzzle Tile | Green leaf match-3 standard piece | Concept (Mockup) | Original creation |
| `tile_sun_blossom` | 256 x 256 px | 1:1 | Puzzle Tile | Yellow flower match-3 standard piece | Concept (Mockup) | Original creation |
| `tile_sky_dewdrop` | 256 x 256 px | 1:1 | Puzzle Tile | Blue droplet match-3 standard piece | Concept (Mockup) | Original creation |
| `tile_royal_plum` | 256 x 256 px | 1:1 | Puzzle Tile | Purple plum match-3 standard piece | Concept (Mockup) | Original creation |
| `tile_blocker_ivy` | 256 x 256 px | 1:1 | Obstacle | Coiled ivy overlay for blocked slots | Placeholder | Procedural texture |
| `tile_special_bomb` | 256 x 256 px | 1:1 | Special | Blossom Bomb 4-match reward tile | Placeholder | Particle effect aura |
| `ui_button_primary_pill` | 512 x 160 px | ~3.2:1 | UI Frame | Green capsule button with bottom bevel | Approved (9-slice) | Luau Gui Frame composition |
| `ui_frame_timber_modal` | 720 x 960 px | 3:4 | UI Frame | Carved cedar wood dialog box border | Approved (9-slice) | Luau Gui Frame composition |
| `ui_icon_star_3d` | 256 x 256 px | 1:1 | Icon | Radiant golden reward star | Concept (Mockup) | Original creation |
| `ui_icon_coin_gold` | 256 x 256 px | 1:1 | Icon | Embossed golden coin | Concept (Mockup) | Original creation |
| `ui_map_node_unlocked` | 192 x 192 px | 1:1 | Map | Carved wooden level node with stars | Concept (Mockup) | Original creation |
| `ui_map_node_locked` | 192 x 192 px | 1:1 | Map | Weathered stone node with padlock | Concept (Mockup) | Original creation |

---

## 2. 3D Environment & Garden Models

| Model Identifier | Polycount Target | Texture Budget | Location | Purpose | Status | Source / Note |
|---|---|---|---|---|---|---|
| `courtyard_fountain_overgrown` | < 3,500 tris | 1024x1024 diffuse | Workspace.GardenArea | Stage 0: Dry cracked fountain covered in moss and vines | Placeholder | Modular Roblox CSG / Meshes |
| `courtyard_fountain_restored` | < 4,000 tris | 1024x1024 diffuse | Workspace.GardenArea | Stage 1: Clean limestone fountain with flowing particle water | Placeholder | Modular Roblox CSG / Meshes |
| `courtyard_paving_stones` | < 1,500 tris | Tileable PBR | Workspace.GardenArea | Courtyard ground floor stone texture | Placeholder | Roblox MaterialService |
| `courtyard_archway_trellis` | < 2,000 tris | 512x512 | Workspace.GardenArea | Wooden perimeter archway with climbing roses | Placeholder | Roblox Studio parts |

---

## 3. Audio & SFX Cues

| SFX Identifier | Length | Volume | Pitch Variation | Trigger Event | Status |
|---|---|---|---|---|---|
| `sfx_tile_tap` | 0.08s | 0.6 | ± 5% | Player taps tile on board | Placeholder |
| `sfx_tile_swap` | 0.15s | 0.7 | None | Tiles slide past each other (whoosh) | Placeholder |
| `sfx_match_pop` | 0.20s | 0.8 | Pitch ascends with cascade count (+1 semitone) | 3+ tiles clear and explode | Placeholder |
| `sfx_cascade_bounce` | 0.12s | 0.5 | None | Falling tiles settle on the floor | Placeholder |
| `sfx_victory_fanfare` | 2.50s | 0.9 | None | Level completed modal opens | Placeholder |
| `sfx_star_collect` | 0.40s | 0.8 | None | Star flies from board into top HUD | Placeholder |
| `sfx_task_restore` | 1.80s | 0.85 | None | Hammer action & sparkle sound during restoration | Placeholder |

---

## 4. Typography & Fonts

| Font Name | Asset Source | Licensing | In-Game Role |
|---|---|---|---|
| `FredokaOne` | Roblox Built-in (`Enum.Font.FredokaOne`) | Open Font License (OFL) / Roblox Native | Large playful headings & titles |
| `GothamBold` | Roblox Built-in (`Enum.Font.GothamBold`) | Roblox Native System Font | Section headers & prominent numbers |
| `GothamMedium` | Roblox Built-in (`Enum.Font.GothamMedium`) | Roblox Native System Font | Body text, descriptions, & UI button labels |
