# Skystones to App Store: Plan, Steps and Order

Oct 28, 2026 · @Nicholas

## Handoff to Claude Code

This section is the brief for taking over the project. Read it first, then the phases below. Everything marked done is merged to `main`. Status as of November 2, 2026.

### The project

- Sigilstone is a native SwiftUI iOS app (iOS 17.5 target): a 3x3 tile-capture strategy game with a runes theme, rebranded from an earlier game. The repo is private at github.com/nickr145/Sigilstone and the default branch is `main`. Work only in `/Users/nrebello/Documents/Sigilstone`
- It is a classic Xcode project (`Sigilstone.xcodeproj`, scheme `Sigilstone`, test target `SigilstoneTests`) with explicit file references, so a new Swift file must be added to the right target in the project, not just created on disk
- CI (`.github/workflows/ci.yml`) builds and runs the tests on every push and pull request to `main`. Run the tests locally with `xcodebuild test -project Sigilstone.xcodeproj -scheme Sigilstone -destination 'platform=iOS Simulator,name=<an iPhone from xcrun simctl list devices available>'`
- Tests use XCTest, not Swift Testing. Shared helpers: `SeededGenerator` and `TestPositions` for deterministic random games, and `InMemoryPersistenceStore` and `SpyAnalyticsService` as test doubles

### Code layout

- `Engine/` holds the pure rules, with no UI and no side effects: `BoardGeometry` (neighbors), `GameState` (board, both hands, current player, per-cell elements, blocked cells, and derived empty cells, game over, scores and winner), `CaptureRules`, `Scoring`, `GameRules` (`isLegal`, `legalMoves`, `breaks`, `capturedCells`, `apply`), `BoardGenerator`, and `AIStrategy` with `AILevels` (random, corner, capture-first for levels 3 and 4, greedy capture for level 5, look-ahead for level 6)
- `Models/` holds `Stone` (id, four edges, owner, optional element), `Element` (fire, water, earth, air, placeholder names), the fixed hands per level in `PlayerPiecesModel`, and `PlaceholderElements`
- `ViewModels/GameViewModel` holds one `GameState` plus UI state and side effects, and exposes forwarders (`board`, `player1Pieces`, `player2Pieces`, `currentPlayer`, scores). `computerTurnToken` is bumped whenever the computer is due to move, and `PVCView` watches only that. Stats and analytics are recorded for PvC games only
- `Views/` holds the screens (`PVCView`, `PVPView`, `GameBoardView`, `PieceSelectionView`, `StoneView`, `EmptyCellView`, `TitleView`, `DifficultySelectionView`, `InstructionsView`). `Services/` holds UserDefaults persistence and a console-only analytics hook, which the privacy manifest assumes collects nothing

### Where things stand

- Phase 1 (rebrand and IP cleanup) is done: no borrowed art, audio or names remain, and the work lives in a fresh private repo
- Phase 2 (rules engine) is done, including the AI as strategies behind one protocol
- Phase 3 (elemental squares and blocks) has its engine work merged in three PRs, and `main` has 82 passing tests. PR 4, which puts squares on screen, is open as #7 with 91 passing tests, waiting for the owner's manual checks and merge
- Next, in order: merge PR 4, then Phases 4 to 8 as laid out below. The pre-match display of elemental squares and fixed layouts per campaign node belong to Phase 5

### How to work

- One small PR per step, branched from an up-to-date `main`. The app must build, the tests must pass and the game must play after every step. Open the PR and do not merge it; the owner merges
- Rule changes are test-first: write the failing test, show that it fails, then change the code. Refactors get characterization tests before any code moves, and must not change behavior
- For anything that touches more than a few files, or starts a phase, report findings and a plan first, then wait for approval
- The engine stays pure. Views never contain rules. Randomness is injected as a `RandomNumberGenerator` so tests are deterministic
- Run the full test suite before every commit and keep CI green. Never rewrite git history or change the remote
- Stop and ask if a change would alter how a game plays, or if a decision in the table near the end of this doc is still open
- You cannot click through the simulator. List the manual checks in the PR description and let the owner run them
- Keep this doc current: when a step is done, tick its checklist items and add a one-line status

### What stays with the owner

- Original art and audio (none ships today; the app icon is a temporary generated placeholder) and any trademark checks
- App Store paperwork: Developer Program enrollment, the final bundle ID (currently `nr.sigilstone`, permanent once the App Store Connect record exists), screenshots, privacy answers and submission
- Manual playthroughs, merging pull requests, and the open decisions in the table

### Known gaps

- Levels 3 and 4 share one strategy, level 5 draws one random stone per cell, and the level 6 look-ahead judges the opponent's reply without applying its own captures. Phase 6 replaces them with real search
- Element names, colors and symbols, and the elements on each hand's stones, are placeholders until Phase 4 designs the tile set
- Back from a finished PvC game returns to the home menu; the Phase 5 result screen fixes it
- `GIFView.swift` is unused code left from the removed animations
- CI pins Xcode 16.4 while the owner's machine runs a newer Xcode. Check Apple's current SDK requirement for submissions before Phase 8

## Goal and scope

The app is publishable once it has an original identity, player-built decks, elemental squares and blocks, and a progression loop, all running on a tested rules engine. The phases below are ordered so each one unblocks the next.

Must-haves for v1:

- Original name, theme, art and audio, with nothing taken from Skylanders
- Core rules kept: 3x3 board, four directional values per tile, capture on a higher facing value, majority wins
- Elemental squares and blocks
- Decks the player builds from a collection, not fixed tiles per opponent
- First-win rewards, gold, a shop and a local save
- PvP, plus a single-player campaign map of NPC matches with a graded AI

Order of work:

1. Rebrand and IP cleanup
2. Rules engine refactor and tests
3. Elemental squares and blocks
4. Deck building and collection
5. Campaign map, NPC progression, rewards and shop
6. AI upgrade and balance simulation
7. Polish and accessibility
8. Ship

## Phase 1: Rebrand and IP cleanup

Remove everything that identifies Skylanders before any other work, because App Review guideline 5.2 (intellectual property) rejects borrowed IP and every later asset depends on the new theme. Game rules are generally not what is protected; names, art, audio and characters are. This is not legal advice.

- [x] Pick a new name and check it is free on the App Store and as a domain
- [x] Pick a theme (runes, crystals or constellations) that makes elements and blocks feel natural
- [x] Replace the Skystones name and the word "blades" with your own terms
- [x] Audit every asset: GIF board backgrounds, portal effects, per-level music, tile art, on-screen text
- [x] Swap in original or properly licensed assets and keep a license record for each
- [x] Rename the Xcode project, bundle ID, README and repo description
- [x] Decide what to do about old assets still in the public git history (new repo or make it private)

Done when no Skylanders name, art or audio remains in the app or its README.

Status: done on October 29, 2026.

- The app is now Sigilstone, with a runes theme; the code, Xcode project, bundle ID and README all use the new name
- Every borrowed image, GIF and mp3 was deleted instead of replaced, so the app ships with no audio and a generated placeholder icon until original assets exist
- The work lives in a new private repo with a single-commit history; the old repo is archived privately as sigilstone-archive
- Along the way, the audit-branch hardening (tests, persistence layer, privacy manifest, CI) and a PvC game-restart fix were merged, and CI runs 20 tests

Asset record (the license record for Phase 1, one row per asset):

| Asset | Source | Status |
| --- | --- | --- |
| Placeholder app icon | Generated programmatically, no external art | Original; temporary, replace before launch |
| background-LC color set | Plain color set, no image | Original |
| Music and sound | None | Nothing shipped; add original audio later |
| Other images and animation | None | Nothing shipped |

Still open from Phase 1:

- Replace the placeholder icon with an original design before Phase 8
- Decide the final bundle ID before creating the App Store Connect record, since it cannot change afterward (currently nr.sigilstone)
- Delete the old local folder and the archived repo after a couple of weeks, once the archived repo has been checked for forks

## Phase 2: Rules engine refactor

Pull the rules out of `GameViewModel` into a pure engine so every later feature (elements, blocks, decks) can be added and tested without touching the UI. Today the view model owns game state and every AI strategy; that is the part that gets fragile as rules grow.

- [x] Define `GameState` as a value type: board, hands, owners, current player (blocks arrive in Phase 3)
- [x] Write `legalMoves(state)` and `apply(move, state)`, both free of UI and side effects
- [x] Move `canCapture` and the neighbor lookups into the engine
- [x] Define an `AIStrategy` protocol and port levels 1 to 6 behind it
- [x] Unit tests: each capture direction, multi-capture, tiles changing hands back and forth, full board, win and tie
- [x] Slim `GameViewModel` down to holding a `GameState`, calling the engine and publishing UI state

Done when all six AI levels behave as before and no rule lives in a view.

Status: done on October 31, 2026.

- The rules live in an `Engine/` folder: board geometry, `GameState`, capture rules, scoring, `GameRules` (`isLegal`, `legalMoves`, `apply`) and the six AI levels as strategies behind `AIStrategy`
- `GameViewModel` holds one `GameState`, calls the engine and publishes UI state; the computer's turn is signaled by a token the view model bumps, so the view no longer infers it
- The suite grew from 20 to 62 tests, including characterization tests written before any code moved and side-by-side checks that the new AI chose what the old AI chose

Follow-ups found along the way, to fix as small separate changes with their own tests:

- Fixed: after a PvP game ended, resetting refilled both hands with the Level 1 hands; PvP now refills the hands it started with (test added)
- Fixed: stats and analytics were recorded for PvP games too, labeled as PvC; they now cover PvC games only (test added)
- Levels 3 and 4 share one strategy and level 5 draws one random stone per cell, so the levels are closer than their names suggest; Phase 6 replaces them with real search
- The level 6 look-ahead judges the opponent's reply without applying its own captures, a quirk kept so the refactor changed no behavior; Phase 6 search fixes it

## Phase 3: Elemental squares and blocks

Add the two missing rules once the engine is tested: a stone placed on a mismatched elemental square breaks, and a broken stone becomes a permanent block. Settle the open rule questions in the last section of this doc before you start.

- [x] Add an `Element` enum, an optional element per board cell and an optional element per tile
- [x] Mismatch rule: the stone breaks and the cell becomes a block
- [x] Blocks cannot be played on, cannot be owned and do not count toward the final score
- [x] Board generator: 1 to 2 elemental squares per match so boards stay fair
- [x] Show elemental squares on the board, using a symbol as well as a color (showing them before the match starts moves to the Phase 5 pre-match screen)
- [x] Update win and tie logic for boards with fewer scoring tiles
- [x] Teach the AI to weigh breakage risk when it picks a cell
- [x] Tests for breaking, blocked cells, scoring with blocks and a board that fills with blocks

Done when a full match with elements and blocks plays correctly against all six AI levels.

Status: code complete on November 2, 2026; PR 4 (#7) is open and waits for the owner's manual checks and merge.

- Squares and blocks are drawn on the board in PvC and PvP, with a symbol and a color per element, and 60 full PvC games with squares on (levels 1 to 6) end with stones plus blocks equal to 9
- `GameViewModel.maxElementalSquares` defaults to 0, so unit tests use plain boards; the two game screens set it to 2
- The suite is at 91 tests. The committed branch before PR 4 always placed 3 random squares, which could hang two PvP tests that looped on the first nil cell; the plain default fixed it

Rules decided:

- A stone placed on an elemental square breaks unless its element matches the square's. A stone with no element breaks too, so the squares become a deck-building choice, and the board is shown before the match
- A broken stone captures nothing; it becomes a permanent block that cannot be played on, cannot be owned and does not score
- Blocks make ties possible; a tie is a draw with no reward, and the player retries
- Elemental squares are fixed per campaign node and random in free play

Plan, one small PR each so the app works after every step. PRs 1 to 3 are merged and PR 4 is open (#7) and waiting for the owner's review and manual checks:

- Merged, PR 1: the data model. `Element`, a stone's element, per-cell elements and a set of blocked cells on `GameState`; blocked cells are not empty and are not legal moves
- Merged, PR 2: the break rule in `GameRules.apply`, with `GameRules.breaks`
- Merged, PR 3: AI levels 3 to 6 evaluate moves through `GameRules`, so they see breakage; levels 1 and 2 stay naive on purpose
- Open, PR 4: board generator and the UI, on branch `feature/elemental-squares-on-screen`

PR 4, what is left. The owner has already written `Engine/BoardGenerator.swift` (`BoardGenerator.elementalSquares(count:using:)`), `Models/PlaceholderElements.swift` (`PlaceholderElements.assign(to:)` gives the first four stones of a hand fire, water, earth and air and leaves the fifth neutral, until Phase 4's tile set replaces it) and `BoardGeneratorTests`. Check that with `git status` and the test count (86), then finish the rest:

- `GameViewModel`: add `var maxElementalSquares = 0` (default 0, so unit tests stay on plain boards), a private `newSquares()` that returns an all-plain layout when the max is 0 and otherwise a random count from 1 to the max through `BoardGenerator` with the system generator, and a private `withElements(_:)` that applies `PlaceholderElements` only when the max is above 0
- `setupComputerDifficulty` sets `gameState.cellElements` from `newSquares()` and gives both hands their placeholder elements. `resetGame` builds the new `GameState` the same way, with PvC hands from `pieces(forDifficulty:)` and PvP hands from the ones the game started with
- Tests in `GameViewModelTests`: games are plain by default; PvC setup with squares on; `resetGame` makes a new layout of 1 to 2 squares with no blocks each time; PvP reset with squares on; and 60 full PvC games (levels 1 to 6, ten each) with squares on, each ending with stones plus blocks equal to 9. Change `playFullPVCGame` to pick `viewModel.gameState.emptyCells.first!` for the human's cell, because the first nil cell can now be a block. Expect 91 tests
- Views: `Views/ElementStyle.swift` (SF Symbol and color per element: flame.fill orange, drop.fill cyan, mountain.2.fill green, wind mint, plus a display name); `Views/BlockView.swift` (dark rectangle with xmark.octagon.fill and the accessibility label Blocked cell N); `EmptyCellView` takes an optional element, tints the cell, draws the symbol and names the element in its accessibility label; `StoneView` shows a white element symbol between the side numbers and names the element in its accessibility label; `GameBoardView` draws a stone, a block or an empty cell with its element for each index
- `PVCView.onAppear` sets `maxElementalSquares = 2` before `setupComputerDifficulty`. `PVPView.onAppear` sets it to 2 and calls `resetGame()` once, guarded so a screen that re-appears does not reset a game in progress
- Manual checks for the owner, to put in the PR description: PvC at level 1 and level 6 shows 1 or 2 squares with symbols; a mismatched or plain stone on a square becomes a block and flips nothing; a matching stone stays; higher levels avoid breaking; Game Over then OK gives a new layout; PvP behaves the same

## Phase 4: Deck building and collection

Letting the player choose tiles from a collection turns each opponent from a repeated puzzle into a game with real decisions. This phase is also where the tile set gets designed, so balance it by rule rather than by feel.

- [ ] Define a `Tile` model: id, four edge values, optional element, rarity
- [ ] Set a stat budget per rarity tier (edge values sum within a fixed range) so no tile strictly beats another
- [ ] Generate the tile set with a script instead of by hand; the original game has 80, and your launch count is your call
- [ ] Collection screen: grid view, filters by rarity and element, silhouettes for tiles not yet owned
- [ ] Deck builder: pick a fixed number of tiles, save more than one deck
- [ ] Give each opponent a deck drawn from the same tile pool
- [ ] Turn order: coin flip by default instead of the opponent always going first

Done when a player can build a deck, enter a match with it and see the opponent use tiles from the same pool.

## Phase 5: Campaign map, NPC progression, rewards and shop

Progression gives the player a reason to come back: a first win against an NPC unlocks a new tile, rematches pay gold, and gold buys tiles. This covers the rewards and collection rules you listed as missing.

- [ ] NPC roster: portrait, deck, AI level (reuse levels 1 to 6) and one unique reward tile each
- [ ] First win grants the reward tile; later wins grant gold
- [ ] A loss or a tie grants nothing and the player retries
- [ ] Shop: buy tiles with gold at fixed prices by rarity
- [ ] Persistence: save collection, decks, gold and defeated NPCs locally (`Codable` to a file, or SwiftData)
- [ ] Campaign map screen that shows which NPCs are beaten and which are next (see the design below)
- [ ] Pick a business model: paid app or one-time unlock; if you ever add randomized packs, Apple requires odds disclosure

Done when a new player can beat the first NPC, earn a tile, spend gold, quit the app and find everything saved on relaunch.

### Campaign map

The campaign replaces the plain difficulty picker with a single-player map: a winding path of nodes, each one an NPC match, in the style of mobile campaign maps. Take the structure from that genre but make the art, names and layout your own, because borrowed map art is the same IP problem as Phase 1.

How it plays:

- Each node is an NPC with a name, a deck, an AI level (reuse levels 1 to 6) and one unique reward tile
- Beating a node unlocks the next one, and later nodes use higher AI levels and stronger decks
- Each node awards 1 to 3 stars, so there is a reason to replay: 1 for a win, 2 for winning by 3 or more stones, 3 for winning by 5 or more (starting values, to be tuned)
- A first win grants the node's reward tile; replays pay gold, with a bonus when you beat your best star count
- Nodes are grouped into chapters of 5 to 8, themed by rune or element, and each chapter ends in a boss with a stronger deck
- Every match ends on a result screen with Play again and Back to map, which also fixes the current dead end after a PvC game

What to build:

- [ ] Define campaign node data: id, name, map position, NPC deck, AI level, reward tile, prerequisite node ids
- [ ] Map screen: a scrolling path where each node shows locked, available or beaten, plus its stars
- [ ] Result screen: win, loss or tie, stars earned, rewards, then Play again or Back to map
- [ ] Keep the star rules in one place so the Phase 6 simulation can tune them
- [ ] Save cleared nodes and best stars with the rest of the progress data
- [ ] Chapter structure and boss nodes
- [ ] v1 map art: a simple original background with nodes drawn in SwiftUI; illustrated chapter maps can come in updates

Done when a new player can clear the first node, see the next one unlock, replay for more stars and find it all saved on relaunch.

## Phase 6: AI upgrade and balance simulation

On a 3x3 board a full search is cheap, so the top AI can look all the way to the end of the game and difficulty becomes a dial instead of a set of separate tricks. Run this after the tile set exists, because balance depends on real tiles.

- [ ] Replace the depth-1 lookahead with minimax plus alpha-beta pruning behind the `AIStrategy` protocol
- [ ] Make difficulty a search-depth cap plus some randomness, so lower levels still play plausibly
- [ ] Build a simulation harness: thousands of AI-vs-AI games across tile and deck pairings, logging win rates
- [ ] Flag tiles and decks with outlier win rates and adjust their stats or rarity
- [ ] Measure first-player advantage and tune the turn-order rule from the result

Done when no tile or deck wins or loses far outside the pack and each AI level feels distinct to a human tester.

## Phase 7: Polish, accessibility and optional Game Center

Feel and accessibility are what separate a project from an app people keep, and they are cheapest to add once the rules have stopped changing.

- [ ] Haptics on placing and capturing, plus a capture flip animation
- [ ] First-run tutorial that teaches capture, elements and blocks by playing a short guided match
- [ ] Settings screen: sound, music and haptics toggles
- [ ] Accessibility: VoiceOver labels, ownership shown by more than color (color-blind safe), Dynamic Type
- [ ] iPad layout
- [ ] Test on real devices for performance and crashes
- [ ] Optional: Game Center achievements, leaderboards and asynchronous turn-based PvP, which avoids running your own server

Done when someone who has never seen the game can learn it from the tutorial alone.

## Phase 8: Ship

Submission is mostly paperwork plus one last IP check, so start the Developer Program enrollment early because approval can take time.

- [ ] Enroll in the Apple Developer Program (about $99 per year; confirm the current price)
- [ ] App icon, screenshots for the required device sizes, description and keywords
- [ ] Privacy policy URL and the App Privacy answers
- [ ] Age rating questionnaire
- [ ] TestFlight beta with friends, then fix what they find
- [ ] Final IP check on every asset, then submit for review
- [ ] If rejected, read the review notes, fix the issue and resubmit

Done when the app is live on the App Store.

## Target code structure

&#91;embedded content: target architecture · 6 modules, rules in one\]

Views talk only to `GameViewModel`. The view model and the AI strategies both call the rules engine, and the tile set, elements and NPC roster feed it.

## Open decisions and risks

Ten decisions shape the rules and scope; each has a default so work does not stall waiting on it.

| Decision | Options | Suggested default |
| --- | --- | --- |
| Theme and name | Runes, crystals, constellations, other | Decided: runes theme, name Sigilstone |
| Mismatch rule | Stone breaks into a block, or a +1 / -1 stat swing | Break into a block (matches your target rules); playtest the softer version |
| Ties | Draw, replay, or a tiebreaker rule | Draw: no reward, player retries |
| Turn order | Opponent always first, or coin flip | Coin flip |
| Hands | Visible to both sides, or hidden | Visible for v1, which makes exact AI search possible |
| Business model | Paid, one-time unlock, free | Paid or one-time unlock; no random packs |
| Online PvP | Game Center turn-based, or skip | Skip until after v1 |
| Tile count at launch | Full 80, or fewer | Fewer at launch, add more in updates |
| Campaign star rules | Win only, margin-based, or no stones lost | Margin-based (win, win by 3, win by 5), tuned in the Phase 6 simulation |
| Free play after the campaign | Keep a quick-match mode with any AI level, or campaign only | Keep it; the AI levels already exist, so it costs almost nothing |

Risks to watch:

- App Review rejects the app over leftover Skylanders names, art or audio
- Scope creep: elements, decks and progression are each a full feature, so finish one phase before starting the next
- Unbalanced tiles make decks feel solved; the Phase 6 simulation is the safeguard
- Asset licenses that are unclear or undocumented
- Old Skylanders-derived assets still exist in the archived private repo: keep it private, and check it for forks before deleting it
- Campaign map art is a large asset job: ship v1 with a simple original map and add illustrated chapters in updates
