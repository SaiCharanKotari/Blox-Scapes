# Project Bloomtrail — Acceptance Tests & Verification Matrix

**Document Version:** 1.0  
**Phase:** Gate 0 (Pre-Production)  
**Standard Test Policy:** No feature is declared "done" without automated test coverage and visual runtime proof.

---

## 1. Automated Pure Luau Unit Tests (`BoardLogic`)

Pure Luau unit tests run in command-line runner (`rojo test` / Luau CLI) or Roblox Studio command bar without requiring 3D rendering.

### Test Suite 1: Grid Initialization & Legality
- `TEST_01_NO_INITIAL_MATCHES`: Assert that a generated board has 0 horizontal or vertical matches of length >= 3.
- `TEST_02_GUARANTEED_LEGAL_MOVE`: Assert that `FindPossibleMoves(grid)` returns a non-empty array (`#moves >= 1`).
- `TEST_03_DIMENSIONS_AND_BOUNDS`: Assert grid size matches `width * height` and all coordinates `(x, y)` contain non-nil tiles.

### Test Suite 2: Swap Validation & Adjacency
- `TEST_04_REJECT_NON_ADJACENT_SWAP`: Assert swapping `(1, 1)` with `(1, 3)` returns `valid = false` and leaves grid unchanged.
- `TEST_05_REJECT_DIAGONAL_SWAP`: Assert swapping `(1, 1)` with `(2, 2)` returns `valid = false`.
- `TEST_06_REVERT_FAILED_SWAP`: Assert a swap between adjacent tiles that results in no match reverts both tiles to their original coordinates.
- `TEST_07_EXECUTE_VALID_SWAP`: Assert swapping two tiles that forms a 3-in-a-row returns `valid = true` and updates tile positions.

### Test Suite 3: Match Detection & Intersections
- `TEST_08_HORIZONTAL_MATCH_3`: Assert 3 matching tiles horizontally are identified and marked for destruction.
- `TEST_09_VERTICAL_MATCH_3`: Assert 3 matching tiles vertically are identified and marked for destruction.
- `TEST_10_L_SHAPED_INTERSECTION`: Assert a 3x3 L-shape match groups all 5 matching tiles without duplicate counting.
- `TEST_11_MATCH_4_CREATES_SPECIAL`: Assert a 4-in-a-row match spawns a `BlossomBomb` at the swap target coordinate.

### Test Suite 4: Gravity, Refill & Cascades
- `TEST_12_TILES_FALL_INTO_GAPS`: Assert empty spaces created below tiles cause upper tiles to shift downward by the exact empty gap count.
- `TEST_13_TOP_REFILL_FILLS_GRID`: Assert after gravity resolution, all top grid slots are refilled with valid colors from `allowedColors`.
- `TEST_14_CASCADE_RESOLUTION`: Assert falling tiles that form secondary matches trigger subsequent clears until the board is completely stable.
- `TEST_15_CASCADE_SAFETY_LIMIT`: Assert cascade loop breaks safely if max iterations (25) are reached without an infinite loop hang.

---

## 2. Server-Authoritative Integration Tests

- `TEST_NET_01_RATE_LIMIT_DROP`: Rapidly fire 15 `RequestSwap` calls in 0.5s; assert server rejects excess calls and logs no errors.
- `TEST_NET_02_REJECT_OUT_OF_BOUNDS`: Client sends `(99, 99)` coordinate; server returns `valid = false`.
- `TEST_NET_03_PREVENT_REWARD_SPOOFING`: Client attempts to invoke remote directly claiming level win; server rejects unauthorized state transition.
- `TEST_NET_04_STAR_DEDUCTION_FOR_TASK`: Completing Task 1 asserts profile stars decrease by 1 and completed task list is updated.

---

## 3. Manual Verification & Device Playtest Matrix

| Step ID | Test Description | Expected Behavior | Pass Criteria |
|---|---|---|---|
| **MAN_01** | Mobile Portrait Layout Inset | Open game on iPhone 13 emulator portrait mode. UI does not clip notch, camera island, or home bar. | All HUD buttons and bottom controls fully visible with >= 10px safe margins. |
| **MAN_02** | Tap-to-Select & Tap-to-Swap | Tap tile at `(3, 4)`. Tile elevates slightly with a pulsing highlight. Tap adjacent tile `(3, 5)`. | Tiles swap smoothly. If matching, pop particles trigger; if invalid, tiles bounce back. |
| **MAN_03** | Objective Tracking HUD | Complete a match of 3 leaves. | Leaf objective counter decrements by 3 in real-time with small pulse tween. |
| **MAN_04** | Move Exhaustion / Defeat | Reach 0 moves with objectives uncompleted. | "Out of Moves" modal appears. Clicking "Retry" resets board cleanly. |
| **MAN_05** | Victory Flow & Star Grant | Complete all objectives with moves remaining. | "Level Completed!" celebration modal displays. +1 Star and +50 Coins animate to HUD. |
| **MAN_06** | Progression Map Unlock | Return to Progression Map after beating Level 1. | Level 1 shows 1-3 stars. Node 2 unlocks with golden glow and play prompt. |
| **MAN_07** | Garden Restoration Action | Navigate to Garden Courtyard. Tap "Clean Fountain" task card (Cost: 1 Star). | 1 Star deducted. Overgrown moss and ivy vanish from the 3D fountain model. Water starts flowing. |
| **MAN_08** | Save & Reconnect Persistence | Exit Studio playtest and restart. | Player profile loads automatically. Level 2 remains unlocked, stars balance is accurate, fountain remains clean. |

---

## 4. Gate 0 Release Checklist

Before Gate 0 is approved:
- [x] Workspace inspected and verified non-destructive.
- [x] All 7 Gate 0 documents created in `docs/`.
- [x] Rojo project config (`default.project.json`) established.
- [x] Visual direction, exact tokens, and layout guidelines established.
- [x] Pure Luau architecture and server-authority boundaries specified.
- [x] 4 mobile portrait concept mockups generated and reviewed.
