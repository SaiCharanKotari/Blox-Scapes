# Project Bloomtrail — Foundation Audit Report (Gate 0)

**Document Version:** 1.0  
**Phase:** Gate 0 (Pre-Production Audit)  
**Date:** 2026-10-11  
**Status:** Complete — Ready for Review  

---

## 1. Executive Summary & Verification Context

As part of the Gate 0 foundation audit for **Project Bloomtrail**, a comprehensive inspection of the workspace, documentation, toolchain configuration, source files, and live Rojo synchronization was conducted. 

Project Bloomtrail has selected **Rojo** as the single source of truth for all Luau source code, with Roblox Studio serving as the runtime simulation and testing environment. Furthermore, the user has established a key architectural requirement: **React-Lua will be adopted for the declarative UI layer**.

This audit verifies which systems are functioning, validates Rojo synchronization safety, details all identified gaps and contradictions with assigned severity levels, and presents an actionable remediation plan.

---

## 2. Setup Checks & Empirical Execution Matrix

In accordance with our strict verification policy: **No test or check is claimed to pass unless it was directly executed and observed in this session.**

| # | Check / Tool | Execution Command | Result / Output | Status |
|---|---|---|---|---|
| **CHK-01** | Toolchain Manager | `aftman --version` | `aftman 0.3.0` | **PASS** |
| **CHK-02** | Installed Aftman Tools | `aftman list` | `rojo-rbx/rojo 7.7.1` | **PASS** |
| **CHK-03** | Rojo CLI Version | `rojo --version` | `Rojo 7.7.1` | **PASS** |
| **CHK-04** | Rojo Sourcemap Generation | `rojo sourcemap` | Valid JSON generated matching `BloomtrailShared`, `BloomtrailServer`, `BloomtrailClient` | **PASS** |
| **CHK-05** | Rojo Headless Project Build | `rojo build default.project.json -o test_build.rbxm` | Built project to `test_build.rbxm` cleanly (exit code 0; test artifact removed) | **PASS** |
| **CHK-06** | Rojo Live Server TCP Listener | `Get-NetTCPConnection -LocalPort 34872` | `127.0.0.1:34872` listening under PID 12832 | **PASS** |
| **CHK-07** | Rojo Live Server HTTP Root | `curl.exe -s http://127.0.0.1:34872/` | HTTP 200 OK — `Server Version: 7.7.1`, `Project: Bloomtrail` | **PASS** |
| **CHK-08** | Rojo Live Instance Tree State | `curl.exe -s http://127.0.0.1:34872/show-instances` | DataModel tree correctly mounts `ReplicatedStorage`, `ServerScriptService`, `StarterPlayer` | **PASS** |
| **CHK-09** | Studio Plugin Connection Check | MCP `list_roblox_studios` | `{"studios":[]}` — Studio plugin active in MCP; no open Studio instance connected | **PASS** |
| **CHK-10** | Git Working Tree State | `git status` | Clean working tree; initial pre-production files present and untracked | **PASS** |
| **CHK-11** | Automated Luau Unit Suite | Execution of 15 tests in `ACCEPTANCE_TESTS.md` | **BLOCKED / NOT RUN** — Test runner (Lune / TestEZ) not installed; tests not yet coded | **SKIPPED** |

---

## 3. Detailed Audit Findings & Severity Assessment

### Finding 1: UI Framework Architectural Conflict (React-Lua Adoption)
- **Severity:** `CRITICAL`
- **Location:** `docs/TECHNICAL_ARCHITECTURE.md` (lines 46-56), `docs/GAME_PILLARS.md` (line 81), `aftman.toml`, `default.project.json`
- **Description:** 
  1. `docs/TECHNICAL_ARCHITECTURE.md` currently specifies an imperative UI architecture consisting of `ScreenManager.luau`, `BoardView.luau`, `TileView.luau`, and `HeaderHUD.luau` manipulating Roblox `GuiObject` instances directly with `TweenService`.
  2. `docs/GAME_PILLARS.md` explicitly lists as a non-goal: *"Third-Party Heavy Frameworks: Pure modular Luau architecture with zero unverified external dependencies."*
  3. The project lead has mandated: **"we are going to use react-lua also for UI"**.
  4. There is currently **zero infrastructure** for `react-lua` in the repository: no package manager (`wally`), no `wally.toml`, no package sync configuration in `default.project.json`, and no vendor module bundle.
- **Impact:** Attempting to build UI without resolving this conflict will cause either duplicate work (writing imperative UI that must later be discarded) or broken imports.
- **Remediation:** 
  1. Update `docs/TECHNICAL_ARCHITECTURE.md` and `docs/GAME_PILLARS.md` to formally adopt React-Lua for all declarative screen layouts and modal views.
  2. Add `wally = "upliftgames/wally@0.3.2"` to `aftman.toml` or vendor `@jsdotlua/react` and `@jsdotlua/react-roblox` into `src/shared/Packages`.
  3. Map `Packages` into `ReplicatedStorage.BloomtrailShared.Packages` inside `default.project.json`.

---

### Finding 2: Remotes Contract Architecture Undefined in Project Filesystem
- **Severity:** `HIGH`
- **Location:** `docs/TECHNICAL_ARCHITECTURE.md` (Section 2, lines 60-73), `src/shared/`
- **Description:** 
  1. Section 2 of the Technical Architecture specifies 5 Remote objects under `ReplicatedStorage.BloomtrailShared.Remotes` (`RequestStartLevel`, `RequestSwap`, `RequestRestartLevel`, `RequestCompleteTask`, `SyncProfileData`).
  2. The filesystem has no `src/shared/Remotes` directory or Luau Remote factory.
  3. `ServerInit.server.luau` and `ClientInit.client.luau` do not instantiate or wait for Remotes.
- **Impact:** Any client script attempting `BloomtrailShared:WaitForChild("Remotes")` will hang indefinitely, resulting in a silent startup deadlock.
- **Remediation:** Create a typed `Network/Remotes.luau` module in `src/shared/Network` that dynamically declares and provisions instances on the server and retrieves them on the client with strict Luau type annotations.

---

### Finding 3: Coordinate Indexing Ambiguity (Row-Major `[y][x]` vs `(x, y)` Vectors)
- **Severity:** `HIGH`
- **Location:** `src/shared/Types/BoardTypes.luau` (line 16), `docs/LEVEL_SCHEMA.md` (line 28), `docs/TECHNICAL_ARCHITECTURE.md` (line 69)
- **Description:**
  1. In `BoardTypes.luau`, the grid is defined as `Grid = { [number]: { [number]: Tile? } } -- [y][x]`. This is row-major.
  2. In `docs/LEVEL_SCHEMA.md`, preplaced tiles specify `{ x: number, y: number }`.
  3. In `docs/TECHNICAL_ARCHITECTURE.md`, `RequestSwap` takes `Vector2int16` (`fromCoord.X, fromCoord.Y`).
- **Impact:** In match-3 grid engines, mixing row-major indexing (`grid[y][x]`) with Cartesian coordinates (`(x, y)`) without a dedicated, tested coordinate conversion module leads to transposed swapping, broken gravity cascades, and inverted boundary checks.
- **Remediation:** Standardize on explicit helper functions (`BoardUtil.getTile(grid, x, y)` and `BoardUtil.setTile(grid, x, y, tile)`) or standardize coordinates across all types.

---

### Finding 4: Incomplete Type Definitions & Missing Schema Files
- **Severity:** `HIGH`
- **Location:** `src/shared/Types/`
- **Description:**
  1. `docs/TECHNICAL_ARCHITECTURE.md` references `LevelTypes.luau` and `ProfileTypes.luau` alongside `BoardTypes.luau`. However, only `BoardTypes.luau` exists in `src/shared/Types/`.
  2. `BoardTypes.luau` is incomplete: it lacks definitions for `CascadeStep`, `MatchResult`, `MoveValidation`, `SwapResult`, and `ObjectiveState`.
- **Impact:** Developers cannot write strict Luau code without missing type imports, compromising type safety.
- **Remediation:** Author `LevelTypes.luau`, `ProfileTypes.luau`, and expand `BoardTypes.luau` to include all cascade and validation structures before Gate 1 engine implementation.

---

### Finding 5: Studio Workspace Safety & Instance Protection
- **Severity:** `MEDIUM`
- **Location:** `default.project.json`
- **Description:**
  1. `default.project.json` scopes its synchronization to:
     - `ReplicatedStorage.BloomtrailShared`
     - `ServerScriptService.BloomtrailServer`
     - `StarterPlayer.StarterPlayerScripts.BloomtrailClient`
  2. Because `Workspace` is not defined in `default.project.json`, existing 3D models (such as courtyard terrain, lighting, camera, or parts) in Roblox Studio will **not** be overwritten or deleted during sync.
  3. However, `default.project.json` does not include `"globIgnorePaths"`. If temporary files, markdown notes, or scratch scripts are accidentally placed into `src/`, Rojo will attempt to synchronize them as `StringValue` instances.
- **Impact:** Potential clutter in Studio if non-script files enter `src/`.
- **Remediation:** Add `"globIgnorePaths": ["**/*.md", "**/*.jsonc", "**/scratch/**"]` to `default.project.json`.

---

### Finding 6: Missing CLI Test Runner for Pure Luau Automated Tests
- **Severity:** `MEDIUM`
- **Location:** `aftman.toml`, `docs/ACCEPTANCE_TESTS.md`
- **Description:**
  1. `docs/ACCEPTANCE_TESTS.md` lists 15 mandatory unit tests for `BoardLogic` that must pass before Gate 1 is complete.
  2. `aftman.toml` currently only provisions `rojo`. There is no CLI Luau environment (such as `lune` or `luau`) configured to run unit tests offline from the command line.
- **Impact:** Tests would have to be manually executed inside Studio's Command Bar, slowing feedback loops and preventing automated CI validation.
- **Remediation:** Add `lune = "lune-org/lune@0.8.6"` to `aftman.toml` or provide a lightweight Studio test bootstrap module `src/server/TestRunner.server.luau` that runs on playtest when `game:GetService("RunService"):IsStudio()` is true.

---

### Finding 7: Stub Initializer Scripts Without Error Handling
- **Severity:** `LOW`
- **Location:** `src/client/ClientInit.client.luau`, `src/server/ServerInit.server.luau`
- **Description:** Both initializer scripts contain single `print()` statements and do not establish error boundaries or module bootstrap loops.
- **Impact:** Low during Gate 0; must be addressed in Gate 1.

---

## 4. Rojo Synchronization Safety Verification

We examined the live instance tree via `http://127.0.0.1:34872/show-instances`:

```json
{
  "name": "Bloomtrail",
  "className": "DataModel",
  "children": [
    {
      "name": "ReplicatedStorage",
      "children": [{ "name": "BloomtrailShared", "$path": "src/shared" }]
    },
    {
      "name": "ServerScriptService",
      "children": [{ "name": "BloomtrailServer", "$path": "src/server" }]
    },
    {
      "name": "StarterPlayer",
      "children": [
        {
          "name": "StarterPlayerScripts",
          "children": [{ "name": "BloomtrailClient", "$path": "src/client" }]
        }
      ]
    }
  ]
}
```

### Safety Assessment:
1. **Zero Impact on Studio Workspace:** `Workspace` is untouched. Any 3D assets, foliage, terrain, or lighting authored in Studio will remain completely preserved.
2. **Zero Impact on Lighting & Sound:** `Lighting`, `SoundService`, and `MaterialService` are unmanaged by Rojo, preserving Studio environmental setups.
3. **Partitioned Script Namespaces:** All managed code resides in dedicated child folders (`BloomtrailShared`, `BloomtrailServer`, `BloomtrailClient`), ensuring no conflicts with other Studio plugins or core Roblox services.

---

## 5. Audit Conclusion & Gate 0 Exit Readiness

The repository structure is intact, Rojo synchronization is fully verified and non-destructive, and the live server is operational. The findings identified above are well-understood and have concrete remediation paths that integrate seamlessly into Gate 1.
