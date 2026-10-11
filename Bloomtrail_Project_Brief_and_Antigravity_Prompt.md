# Project Bloomtrail
## Roblox Casual Puzzle + Garden Restoration Game

**Status:** Pre-production / Phase 0  
**Working codename:** Bloomtrail (not the final public title)  
**Platform:** Roblox, Luau, Roblox Studio  
**Initial product target:** Portrait-first mobile experience with deliberate PC/tablet adaptations  
**Creative reference:** The broad casual puzzle + garden restoration genre. All characters, artwork, dialogue, names, level layouts, icons, music, and UI compositions must be original.

---

## 1. Product vision

Create a polished, welcoming casual game in Roblox where players complete match-3 puzzles, earn stars and coins, restore a beautiful garden, unlock new areas, and discover short story moments. The main progression is **beating puzzle levels**, not grinding a character level or repeatedly farming the same activity.

The experience should feel like a cohesive mobile casual game rather than a default Roblox simulator with a puzzle minigame attached. A player should understand the goal immediately, enjoy the tactile feedback of each move, and see a visible reward in the garden after completing tasks.

### Core loop

1. Open the vertical garden progression map.
2. Select an unlocked puzzle level.
3. Play a match-3 board with a defined move budget and objective.
4. Win or fail with clear, satisfying feedback.
5. On a win, award stars/coins and unlock the next level.
6. Spend stars on a garden restoration task.
7. See an actual before-to-after change in the garden.
8. Unlock a new task, chapter, or location and repeat.

### Initial audience and design principles

- Easy to understand in seconds; meaningful skill emerges over time.
- Warm, charming, polished, readable, and tactile.
- Short play sessions; no unnecessary waiting between actions.
- Fair difficulty. Never make a level impossible due to bad board generation.
- Responsive on touch devices; mouse and keyboard should also feel intentional.
- The player’s progress should remain clear and persistent.

## 2. Creative direction

### Proposed visual direction: “storybook garden, tactile puzzle pieces”

Create an original art style combining a softly dimensional illustrated garden with crisp, tactile match-3 pieces. Use a clear hierarchy, excellent spacing, rich but controlled color, friendly silhouettes, subtle texture, and purposeful animation. It must look authored, not assembled from unrelated asset packs.

Suggested design tokens to explore, then validate with mockups:

- **Base surfaces:** warm ivory, soft cream, pale stone.
- **Garden colors:** leafy sage, deep botanical green, fresh lime used sparingly.
- **Accent colors:** petal coral, berry, sky blue, muted golden reward accents.
- **Typography:** one highly legible rounded display style for headings and one exceptionally readable UI font for labels/body text. Verify availability/licensing before shipping fonts.
- **Depth:** restrained shadows, layered foliage, clear foreground/midground/background, tactile button states.
- **Motion:** short, purposeful feedback; squash-and-stretch for selected actions; satisfying match/cascade/reward timing; no constant distracting motion.

Do not treat the suggested colors as a substitute for designing a complete palette. Define exact tokens, contrast requirements, type scale, spacing scale, corner radii, shadows, icon treatment, and motion durations in the art bible.

### Hard visual quality rules

- No default-looking Roblox buttons as final UI.
- No emoji used as final production artwork.
- No random font mixing, arbitrary colors, inconsistent radii, or excessive gradients/glows.
- No stretching one mockup to fit every aspect ratio.
- No placeholder assets silently remaining in a “completed” feature.
- No copied Gardenscapes characters, story, art, icons, map composition, screenshots, or exact UI layouts.
- Every screen needs hierarchy, states, feedback, loading/error handling, and small-screen readability.
- If genuine artwork is unavailable, create a coherent temporary kit and label it clearly as placeholder rather than pretending it is final.

## 3. MVP boundaries

### MVP must contain

- An original, vertically scrollable progression map with 10 level nodes.
- A match-3 game board with stable deterministic rules and controlled random generation.
- At least 10 data-configured levels, starting simple and introducing variety.
- Clear move counting, objective tracking, success/failure, restart, and return-to-map paths.
- A small, robust set of special pieces and blockers. Include only mechanics that can be tested correctly.
- A reward loop using stars and coins.
- One garden area with three restoration tasks and visible state changes.
- A lightweight reusable dialogue/story panel, even if MVP story content is short.
- Saved unlocked-level, star, currency, and restoration progress.
- A responsive mobile portrait layout and deliberate PC/tablet adaptation.
- Automated tests for core board rules and a manual playtest checklist.

### Explicitly out of scope for the first vertical slice

- Multiplayer/co-op garden state.
- Guilds, leaderboards, social gifting, live events, seasons, daily quests.
- Paid boosters, random paid rewards, monetization, subscriptions.
- Hundreds of hand-authored levels.
- A complex cinematic dialogue system.
- Multiple gardens or chapters before the first garden loop is stable.
- Third-party framework dependencies unless reviewed and justified.

## 4. System architecture principles

Use small, well-defined Luau modules with explicit ownership. Do not implement the entire game in one large script.

Suggested logical boundaries (adapt to the actual project format after inspecting the repository):

- **Shared/config:** level definitions, objective types, tile definitions, tuning constants, shared types.
- **Puzzle logic:** grid creation, legal swaps, match detection, match grouping, clear/refill/gravity resolution, special-piece behavior, legal-move detection, reshuffling, win/loss evaluation.
- **Client presentation:** board rendering, input, animation sequencing, map UI, garden UI, menus, audio/feedback.
- **Server gameplay authority:** validate swaps, own authoritative puzzle/progression state, validate win conditions and reward grants, handle restart and unlock requests.
- **Persistence:** versioned player profile; robust retries and failure handling; safe handling of concurrent updates; do not silently reset data after a read/write error.
- **Content pipeline:** documented level schema, reusable tile/blocker definitions, asset manifest, predictable naming.

### Authority and exploit resistance

The client may request a move; it must not be able to award itself stars/currency or declare arbitrary level completion. The server must validate adjacency, board state, move count, objective progress, completion and rewards. Use bounded, validated RemoteEvent/RemoteFunction inputs and request rate limits. Keep client visuals responsive while server state remains authoritative.

### Puzzle correctness requirements

- Define a single explicit state machine for swapping, resolving, and accepting the next move.
- Reject non-adjacent swaps and input during resolution.
- A swap without a valid match must revert according to the rules.
- Detect intersecting matches consistently and avoid duplicate counting.
- Resolve cascades until the board is stable, with a hard safety guard against infinite loops.
- Ensure initial boards contain no unintended immediate matches unless a level explicitly requests them.
- Ensure a board has at least one legal move or safely reshuffle it.
- Ensure gravity/refill respects holes, blockers, and board shape.
- Define how special pieces are created, triggered, combined, and counted against objectives.
- Ensure goals cannot be counted twice and moves cannot underflow.
- Winning and losing transitions must occur exactly once.
- Use seeded/testable random generation where practical so bugs can be reproduced.

### Persistence requirements

- Use Roblox DataStoreService for persistent progress when running in a published/test environment where data stores are available.
- Version the profile schema and plan migrations.
- Save only validated server-owned state.
- Handle API throttling, transient failures, shutdowns, and retries without data loss or infinite retry loops.
- Do not wipe a user’s profile just because a load failed.
- Provide a clear local Studio testing strategy, including test profiles or a safe mock implementation.

## 5. Device and UX requirements

- Mobile is portrait-first. Reserve space for device safe areas and Roblox UI insets.
- The board must remain legible and tappable across supported mobile aspect ratios.
- Avoid requiring precise dragging: support clear tap-to-select and tap-to-swap behavior where possible, with optional drag support only if reliable.
- Show the level number, moves remaining, goals, boosters if present, and pause/exit affordance without clutter.
- Distinguish tappable, selected, disabled, locked, loading, success, and failure states.
- Respect reduced visual overload: effects may be delightful but must not obscure game information.
- PC should use sensible wide-screen spacing and mouse input; do not simply enlarge the portrait canvas.
- Test performance and legibility on a lower-end phone, not just Studio on a desktop.

## 6. Development gates

### Gate 0: Pre-production (do this first)

Inspect the existing workspace before touching files. Determine whether the project is a Roblox Studio place, Rojo repository, or empty folder. Do not overwrite existing work.

Create these documents first:

1. `docs/GAME_PILLARS.md` — product pillars, target loop, MVP scope, non-goals.
2. `docs/ART_BIBLE.md` — complete visual tokens, moodboards/reference descriptions, screen hierarchy, animation language, asset list and quality rubric.
3. `docs/TECHNICAL_ARCHITECTURE.md` — folders/modules, client-server contract, data schemas, puzzle state model, persistence and error handling.
4. `docs/LEVEL_SCHEMA.md` — level configuration format plus 3 concrete sample level definitions.
5. `docs/ACCEPTANCE_TESTS.md` — test cases and release gates.
6. `docs/PROJECT_PLAN.md` — milestone sequence, dependencies, risks, and definition of done.
7. `docs/ASSET_MANIFEST.md` — every required asset, dimensions/aspect ratio, use, status (placeholder/approved/final), source and licensing note.

If the environment supports mockups or screenshots, produce a small set of UI concepts for the progression map, puzzle screen, win screen, and restoration screen. If it does not, provide precise annotated layout specifications. Do not begin mass implementation in Gate 0.

### Gate 1: Core puzzle engine

Implement the pure rules and tests without production visuals. Verify edge cases and state transitions. Do not proceed until tests pass.

### Gate 2: One playable puzzle screen

Build one polished, responsive board with input, animation, objectives, moves, win/loss and restart. Test touch and mouse input.

### Gate 3: Progression + garden vertical slice

Connect one level to the map, reward stars, unlock the next node, spend a star on one restoration task, and visibly update the garden.

### Gate 4: Persistence + exploit checks

Verify reconnects, retries, server-side validation, reward duplication prevention, and safe data handling.

### Gate 5: MVP content expansion

Add the remaining MVP levels and restoration tasks through configuration, not one-off scripts. Run regression tests after every content batch.

## 7. Definition of “done”

A feature is not done merely because code was generated. It is done only when:

- It meets the written acceptance criteria.
- The relevant tests pass.
- No new output errors or warnings are left unexplained.
- It was inspected in the actual Roblox runtime, not just source code.
- It works on the target aspect ratios and input modes.
- It has loading, empty, failure, disabled and success states where relevant.
- It does not trust client-supplied rewards or progression.
- Its art matches the approved visual direction.
- Known limitations are documented honestly.

## 8. First task for Antigravity: paste this prompt

> Act as the creative director, senior Roblox/Luau architect, and quality lead for Project Bloomtrail.
>
> **Do Gate 0 only. Do not build the entire game.** First inspect the current workspace and report its structure, project format, existing systems, test commands, and anything that must be preserved. Do not overwrite existing files or assume the repository is empty.
>
> Use the product vision, MVP boundaries, architecture principles, visual quality rules, Roblox constraints, and development gates in this brief as mandatory requirements.
>
> Your biggest risk is poor visual taste and unstructured code generation. Do not default to generic Roblox UI. Before implementation, define a coherent, premium casual-game art direction for an original garden-restoration puzzle game. Specify exact design tokens, typography hierarchy, UI component states, button construction, map layout, tile treatment, icon style, garden scene treatment, and animation timing. Separate inspiration from copying: do not reproduce Gardenscapes' exact assets, characters, story, art, screenshots, or screen compositions.
>
> Create the seven Gate 0 documents listed in this brief. Include concrete design decisions, not vague descriptions. Include a proposed Explorer/folder hierarchy for the actual project format; clear client/server responsibilities; a data-driven level schema; a server-authoritative move/reward flow; persistence/error-handling rules; an asset production manifest; and testable acceptance criteria.
>
> Design the first vertical slice as: open map → enter Level 1 → complete a match-3 puzzle → win and receive a star → return to map → spend the star on one garden restoration task → see the garden visibly change → close/reopen and confirm progress persists.
>
> Keep the first release single-player. Exclude monetization and social systems for now. Avoid unnecessary dependencies. Do not build dozens of levels, add elaborate story cinematics, or start generating large amounts of code before the documents and design direction are reviewed.
>
> If image/mockup tools are available in this environment, create distinct concepts for the progression map, puzzle board, victory screen, and garden restoration screen, with mobile portrait as the primary layout. Otherwise give annotated layout specifications detailed enough for implementation. Treat any generated imagery as a concept until its consistency, resolution, rights and in-game usability have been reviewed.
>
> End by listing: (1) files created, (2) assumptions requiring review, (3) highest-risk decisions, (4) what is explicitly not implemented yet, and (5) the exact Gate 1 task to start next. Do not claim a feature works unless it was run and verified.

---

## 9. First human review checklist

Before approving Gate 0, review these questions:

- Does the progression map feel like a delightful illustrated journey, not a list of generic buttons?
- Is the puzzle board the strongest and clearest element on the gameplay screen?
- Are all pieces, blockers, buttons and rewards visually consistent?
- Can the map, puzzle, victory and restoration screens plausibly belong to the same game?
- Can the first level be beaten, and does the star cause an obvious garden change?
- Are client/server responsibilities and the data schema explicit?
- Are the asset sources and IP/licensing status tracked?
- Does each quality requirement have a way to test or review it?

**Project rule:** polish one complete loop before increasing content quantity.
