# Skystones to App Store: Plan, Steps and Order

Oct 28, 2026 · @Nicholas

## Handoff to Claude Code

This section is the brief for taking over the project. Read it first, then the phases below. Everything marked done is merged to `main`. Status as of November 6, 2026.

### The project

- Sigilstone is a native SwiftUI iOS app (iOS 17.5 target): a 3x3 tile-capture strategy game with a runes theme, rebranded from an earlier game. The repo is private at github.com/nickr145/Sigilstone and the default branch is `main`. Work only in `/Users/nrebello/Documents/Sigilstone`
- It is a classic Xcode project (`Sigilstone.xcodeproj`, scheme `Sigilstone`, test target `SigilstoneTests`) with explicit file references, so a new Swift file must be added to the right target in the project, not just created on disk
- CI (`.github/workflows/ci.yml`) builds and runs the tests on every push and pull request to `main`. Run the tests locally with `xcodebuild test -project Sigilstone.xcodeproj -scheme Sigilstone -destination 'platform=iOS Simulator,name=<an iPhone from xcrun simctl list devices available>'`
- Tests use XCTest, not Swift Testing. Shared helpers: `SeededGenerator` and `TestPositions` for deterministic random games, and `InMemoryPersistenceStore` and `SpyAnalyticsService` as test doubles

### Code layout

- `Engine/` holds the pure rules, with no UI and no side effects: `BoardGeometry` (neighbors), `GameState` (board, both hands, current player, per-cell elements, blocked cells, and derived empty cells, game over, scores and winner), `CaptureRules`, `Scoring`, `GameRules` (`isLegal`, `legalMoves`, `breaks`, `capturedCells`, `apply`), `BoardGenerator`, and `AIStrategy` with `AILevels` (random, corner, capture-first for levels 3 and 4, greedy capture for level 5, look-ahead for level 6)
- `Models/` holds `Stone` (id, four edges, owner, optional element, optional `tileID`), `Element` (fire, water, earth, air, placeholder names), `Tile` and `Rarity`, the generated `TileSet`, and `Deck`, `OpponentDecks` and `Starter` (hands come from decks)
- `ViewModels/GameViewModel` holds one `GameState` plus UI state and side effects, and exposes forwarders (`board`, `player1Pieces`, `player2Pieces`, `currentPlayer`, scores). `computerTurnToken` is bumped whenever the computer is due to move, and `PVCView` watches only that. Stats and analytics are recorded for PvC games only
- `Views/` holds the screens (`PVCView`, `PVPView`, `GameBoardView`, `PieceSelectionView`, `StoneView`, `EmptyCellView`, `TitleView`, `DifficultySelectionView`, `InstructionsView`). `Services/` holds UserDefaults persistence and a console-only analytics hook, which the privacy manifest assumes collects nothing

### Where things stand

- Phase 1 (rebrand and IP cleanup) is done: no borrowed art, audio or names remain, and the work lives in a fresh private repo
- Phase 2 (rules engine) is done, including the AI as strategies behind one protocol
- Phase 3 (elemental squares and blocks) is done: the engine work and the on-screen squares and blocks are merged
- Phase 4 has started: the `Tile` model, rarity budget and generated 36-tile set are merged (#8), and hands come from decks (#10). `main` has 108 passing tests
- The owner has refined the journey design (v2, under "Journey design" in Phase 5): a basic tier and a mostly elementless tile set, a 4-tile tutorial hand, per-NPC reward orders, shop-exclusive tiles, and a `BoardSpec` per node. The 36-tile set, the 8-commons starter collection and the "3 elements" opponent rule are superseded by it and are replaced in PRs 4 and 5
- Next, in order: the PR sequence under "Journey design" in Phase 5 (start with PR 4, the tile set retune, once the owner approves the plan), then Phases 6 to 8. The pre-match display of elemental squares and fixed layouts per campaign node belong to Phase 5

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
- Element names, colors and symbols are placeholders until the tile set retune (Phase 4, PR 4) settles which tiles carry an element
- Every PvC game still places 2 elemental squares, whatever the level; PR 5 replaces this with a board spec per stage
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
- Blocked cells and elemental squares are fixed per campaign node (a `BoardSpec`) and random in free play, by stage: clean boards, then pre-placed blocks, then blocks plus squares (Phase 5)

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

- [x] Define a `Tile` model: id, four edge values, optional element, rarity
- [x] Set a stat budget per rarity tier (one fixed edge sum per tier) so no tile strictly beats another in its tier
- [x] Generate the tile set with a script instead of by hand (the first 36-tile set is merged; the retune below replaces it)
- [x] Hands come from decks: each AI level has a fixed deck from the tile pool, and PvP uses one standard deck (#10). The journey design below changes which decks they are, not the mechanism
- [ ] Retune the tile set: a basic tier, mostly elementless tiles, and a source (starter, campaign or shop) for every tile
- [ ] Deck builder: pick 5 tiles from the owned collection (first version over the whole pool; one saved deck, then more than one)
- [ ] Collection screen: grid view, filters by rarity and element, silhouettes for tiles not yet owned
- [ ] Turn order: coin flip in free play (campaign nodes set their own starting player)

Done when a player can build a deck, enter a match with it and see the opponent use tiles from the same pool.

Decisions for this phase (journey design v2, answered by the owner on November 6, 2026; it replaces the earlier 36-tile design):

- Confirmed: 52 tiles in 5 tiers: basic 10, common 12, uncommon 12, rare 10, epic 8. Most tiles are elementless: 32 plain and 20 elemental (one per element in every tier). The launch range is 48 to 60. Each tile can be owned once; the collection is a set of tile ids, and rewards and the shop never offer an owned tile
- Edges run 1 to 9 with a spread cap of 6. Elemental tiles have a fixed edge sum per tier: 9, 12, 16, 20 and 24 (the four existing sums plus a new basic tier below common). A plain tile gets 1 more (10, 13, 17, 21, 25), because it breaks on every elemental square. Distinct edge sets per sum are enough for every tier (sum 9 has 6 for 4 elemental basic tiles; sum 10 has 9 for 6 plain ones)
- The element-aware dominance rule still holds by construction. A plain tile (sum S+1) can never be dominated by an elemental tile (sum S), because it is higher on at least one edge. A plain tile never dominates an elemental one, because it breaks where the other survives. Two plain tiles in a tier share one sum, so neither dominates. The `+1` compensation therefore does not depend on how many tiles are plain. What changes is feel: on a clean board an elemental tile is simply 1 point weaker, so elements are a bet on later boards
- Every tile has a source: `starter` (the 4 plain basic tiles the player begins with), `campaign` (dropped by NPC nodes, including the tutorial's tile) or `shop` (bought with gold, never dropped). The shop-exclusive set is the 4 rare and 4 epic elemental tiles (8 of 52), and the shop's stock unlocks by chapter. Everything else is campaign. A test checks that every campaign tile is in some node's reward order and that no shop tile is in any node's reward order
- The 4 starter tiles are plain basic tiles with four different edge profiles, for example a one-sided vanguard (one high edge), a two-sided flanker (two high edges) and a defensive anchor (even edges). The tutorial reward is a fifth plain basic tile with yet another profile. These five are hand-specified in the generator, not random picks, and the exact edges are reported in PR 4. A test checks that the five profiles differ: no two share a sorted edge set (a rotation of a tile counts as the same profile) and they do not all share one shape. Plain basic tiles have a sum of 10, which allows 9 distinct edge sets; the sixth plain basic tile is a campaign tile
- Free play and PvP are separate from the campaign. PvP uses a clean board and a standard deck of 5 plain commons for both players. On a clean board an elemental tile is weaker and its element does nothing, so the standard deck has none. Revisit when a board picker exists
- Decks are 1 to 5 tiles. Only a full deck of 5 is allowed in free play and the deck builder; the tutorial hand is 4 tiles. Hands stay visible and never draw from a larger deck, so exact AI search stays possible
- Opponent decks are explicit tile-id lists, per campaign node and, for free play, per level by reference: each level names a representative node by id and uses that node's deck, so no deck exists twice. Until the campaign nodes exist (PR 10), the free-play decks stay as explicit per-level lists. The "every opponent deck covers 3 of 4 elements" rule is dropped because most tiles are elementless. In its place: decks used on boards with elemental squares hold at least 2 elemental tiles, every id in every deck resolves, and deck edge totals follow the tier sums
- The tile set is regenerated, so every tile's edges change even where an id looks the same. A fingerprint test pins the shipped edges, so a later regeneration cannot pass CI until the owner has approved it and the winnability check has been rerun
- `scripts/generate_tiles.py` (fixed seed) writes `Models/TileSet.swift`; rerun it and the TileSetTests after any budget change

Order of work: the PR sequence under "Journey design" in Phase 5 sets the order. It builds a thin vertical slice first (tile set, board specs, reward rules, profile and saving, a basic deck builder, the tutorial, a short map, a basic shop) and polishes the collection grid, multiple decks and the coin flip afterwards. A short plan comes first for each screen.

Status: the `Tile` model and rarity budget are merged (#8), and hands come from decks (#10, 108 tests). The owner has refined the journey design (v2, below). Next is PR 4, the tile set retune, which starts once the owner says the plan (PR #11) is merged.

## Phase 5: Campaign map, NPC progression, rewards and shop

Progression gives the player a reason to come back: each win against an NPC drops a tile from that NPC's deck, repeat wins drain the deck and then pay gold, and gold buys tiles that the map never drops. This covers the rewards and collection rules you listed as missing.

- [ ] NPC roster: name, deck, AI level (reuse levels 1 to 6), board spec and a reward order that starts with a signature tile
- [ ] Reward rule: a win drops the first tile in the reward order that the player does not own; when none is left, it pays gold. A loss or a tie grants nothing and the player retries
- [ ] Shop: buy shop-source tiles with gold at fixed prices by rarity; stock unlocks by chapter
- [ ] Economy table: gold per replay, shop prices and which chapter unlocks which stock, all in one file with tests
- [ ] Persistence: save collection, decks, gold, cleared nodes and unlock flags locally (`Codable` to a file, or SwiftData)
- [ ] Campaign map screen that shows which NPCs are beaten and which are next (see the design below)
- [ ] Pick a business model: paid app or one-time unlock; if you ever add randomized packs, Apple requires odds disclosure

Done when a new player can beat the tutorial, win a tile from the first NPC, spend gold, quit the app and find everything saved on relaunch.

### Journey design

The game is a journey. The player grows a collection and a deck from a small start, and the campaign is how they grow it.

Start and tutorial:

- The player begins with 4 plain basic tiles with four different edge profiles and a tutorial match. Beating it grants a fifth plain basic tile with another profile and completes the 5-tile deck. The deck builder unlocks after that, and free play stays locked until the deck is complete
- The tutorial works with a 4-tile hand because the computer moves first on a clean 9-cell board: the computer plays 5 stones and the human plays 4. The tutorial's starting player is fixed. The tutorial grants its tile through the same reward rule as every other node (its reward order holds the 5th tile)
- The tutorial opponent holds a fixed hand of dedicated scripted tiles that are not in the catalog, and plays level 1. A test must prove a forced win for the human with the exact search (the human wins against every computer reply, computer first). If the starter tiles cannot force a win, the fix is to weaken the opponent's scripted tiles, never to add tiles to the player's hand

Map and rewards:

- A single-player map of NPC nodes, in the style of mobile campaign maps (original art and names). Each NPC has a deck. Each win drops one tile from that NPC's deck that the player does not own, in a fixed order that starts with a signature tile. Once every tile in the NPC's reward order is owned, a win pays gold instead. Only a first win unlocks the next node; a replay never changes what is unlocked
- A node's reward order lists campaign tiles only, so a boss may play a shop-exclusive tile without ever dropping it
- Gold buys shop-exclusive tiles at fixed prices by rarity. Stock unlocks chapter by chapter (the table in the Economy bullet below says which). The campaign never requires buying: the winnability check assumes no shop purchases
- Skip and auto-win items are out of scope for v1

Boards and elements:

- Most tiles are elementless. An elementless or mismatched stone breaks into a block on an elemental square, so elements matter only on late boards
- Boards by stage: early nodes use clean 3x3 boards; middle nodes pre-place 1 to 3 blocked cells; late nodes combine blocks and elemental squares. Each node carries its own `BoardSpec` (blocked cells and elemental squares, fixed per node)
- Free play maps AI level to the same stages with randomly generated specs: levels 1 and 2 clean, 3 and 4 blocks, 5 and 6 blocks plus elemental squares
- The first slice shows a one-sentence hint the first time blocks or elemental squares appear (the seen flags live in the profile; the hint ships with the tutorial and result screens in PR 9). Full scripted teaching nodes for blocks and squares come later (PR 15)

Power scale and PvP:

- Starter and early-opponent tiles are low-power (basic), rising through the tiers to high-stat boss tiles (rare and epic)
- PvP is local only and reward-free: both players use the standard deck. Rewards for online PvP wait until online PvP exists. PvP uses a clean board and a standard deck of 5 plain commons
- Free play (any AI level, with the active deck) stays available once the player has a full deck and pays nothing. Gold and tiles come only from campaign nodes

Data model (pure, in `Models/` and `Engine/`):

- `BoardSpec`: `blocks: Set<Int>` and `cellElements: [Element?]` (9 entries). Validation: cells in range, no block on an elemental square, block count within the stage's limit. `BoardSpec.clean` is the empty spec; `BoardSpec.random(stage:using:)` builds free-play boards through `BoardGenerator`. `GameState` already holds `blocks` and `cellElements`, so it needs no new fields: the spec is applied once at game start, and the view model's `maxElementalSquares` is replaced by a `BoardSpec`
- `MatchSetup`: the player's hand (1 to 5 tiles), the opponent's deck or fixed hand, AI level, `BoardSpec` and starting player. It validates that each side has enough stones for the turns it will take: with `n` empty cells the first mover takes `ceil(n/2)` turns and the second `floor(n/2)`. A player with an empty hand and cells left has no legal move and the game would stall, so this check is a test, not a hope
- `CampaignNode`: id, name, map position, `MatchSetup` data (deck, AI level, `BoardSpec`, starting player), `rewardOrder: [String]` and prerequisite node ids. Repeat-win gold is not stored on the node; it comes from the economy table. Free play does not use nodes, except that each AI level names a representative node whose deck it borrows
- `RewardRules.reward(for outcome, rewardOrder, owned, catalog, gold) -> Reward` where `Reward` is `none`, `tile(id)` or `gold(amount)`. A loss or a tie gives `none`. A win gives the first id in the order that exists in the catalog, is not shop-source and is not owned, else gold. The tests cover: signature first; owned tiles skipped; shop tiles skipped; draining a deck in order, then gold; gold is above zero; an empty or unknown order pays gold; the function is deterministic; and the result never names an owned tile. The caller records a result once per match, so a result screen that redraws cannot pay twice
- `Economy` (one file, `Models/Economy.swift`): every tunable economy number in one table, so tuning is one file. It holds gold per replay for each campaign node, the shop price for each rarity, and the chapter that unlocks each shop tile. Tests: every campaign node has replay gold above zero; every shop tile has a price and an unlock chapter that exists; prices rise with rarity; no non-shop tile is priced; and each chapter's stock is affordable from the replay gold of earlier chapters within a stated number of replays. Winnability thresholds are test constants in one place, not part of this table

Winnability check:

- Collections at a node: the floor is the starter tiles, the tutorial tile and the signature tile of each earlier node. The ceiling is the starter tiles plus every campaign tile of earlier nodes, as if the player had farmed. Neither includes shop tiles
- Normal nodes: a reference player with the best deck from the collection must win at least 50% of seeded games from the floor and at least 70% from the ceiling (starting values, to be tuned; a node may override them, as boss nodes will) against that node's actual AI and board spec, computer moving first. The actual rate for every node, floor and ceiling, is printed by the test and reported in the PR description. A forced win against a perfect opponent is not required of a fair node
- Tutorial: a forced win for the human, proven by exhaustive search in a test (see the tutorial notes above)
- Ladder test: with a fixed deck, win rate does not rise by more than the tolerance as the level rises
- A replay of a cleared node always pays gold above zero, and every campaign tile is reachable from some node's reward order
- Cost: report the runtime of the exact search and the 300-game checks before wiring them into CI. Keep per-PR CI fast: a small seeded smoke subset runs in the normal suite, and the full run is a separate command or scheduled job
- Rerun the full check after any change to the tile set, a node's deck or board, or an AI strategy. The tile-set fingerprint test is what forces that rerun

PR sequence for Phases 4 and 5, a thin vertical slice first. Each PR leaves the app playable, and a short plan comes first for the screens and for any PR that touches more than a few files:

1. Merged: `Tile`, rarity budget and generated tile set (#8)
2. Merged: hands come from decks (#10): the player's hand is the active deck, fixed opponent decks per level from the pool, a standard PvP deck and a difficulty-ladder test. Removed `PlayerPiecesModel` and `PlaceholderElements`
3. (Merged with step 2; the deck builder moved to step 8)
4. Tile set v2: basic tier, 52 tiles (mostly elementless), a source per tile, regenerated set, fingerprint test, and the five starter profiles with their distinctness test. Starter tiles, the standard deck (5 plain commons) and the free-play opponent decks are rewritten, the "3 elements" rule is replaced, and the ladder is re-measured and reported before and after. Everything is still owned in memory
5. `BoardSpec`, stages and `MatchSetup` validation: the view model applies a `BoardSpec` at game start, free-play levels map to stages (clean, blocks, blocks plus squares), and the hand-length check lands. This visibly changes levels 1 to 4 (no squares on 1 and 2, blocks on 3 and 4), so it carries manual checks
6. Reward rule, campaign node types and the `Economy` table: pure and fully tested, no screens
7. Player profile and saving: owned tile ids, active deck (4 or 5 tiles), gold, cleared nodes and unlock flags in one `Codable` value behind `PersistenceStore`
8. Basic deck builder: pick 5 tiles from the owned collection, backed by the profile. A short plan comes first
9. Scripted tutorial match and the result screen: the 4-tile hand, a fixed hand of scripted opponent tiles, the exact-search proof of a forced human win (runtime reported), the first-time hint for blocks and squares, Play again and Back to map. Fixes the dead end after a PvC game
10. Short campaign data (the tutorial plus six nodes, one per AI level; free-play levels switch to borrowing these nodes' decks by id) and the winnability harness, as tests only: floor and ceiling collections, per-node overrides, per-node rates reported, smoke subset in CI, full run separate. Nothing user-visible, so the economy is checked before any player meets it
11. Map screen, rewards and gold, progression gating (deck builder unlocks after the tutorial, free play after a full deck). This PR switches the starting collection from everything owned to the starter tiles only. **This is the riskiest step**: a mistuned economy can leave a new player unable to progress, so it merges only with the step 10 check green at both the floor and the ceiling
12. Basic shop: prices and chapter-gated stock read from the `Economy` table, never offers an owned or campaign tile, unlocks after a set node
13. Collection screen: grid, filters by rarity and element, silhouettes for unowned tiles
14. More than one saved deck
15. Stars (rules kept in one place), chapters, boss nodes and the scripted teaching nodes for blocks and elemental squares
16. Coin flip in free play, with tests for both starting players through the `computerTurnToken` path. It must respect two rules: a 4-tile hand can only be the second mover on a 9-cell board, so free play (full deck) only; and every `MatchSetup` still passes the hand-length check, because blocks change who takes the last turn
17. v1 map art

### Campaign map

The campaign replaces the plain difficulty picker with a single-player map: a winding path of nodes, each one an NPC match, in the style of mobile campaign maps. Take the structure from that genre but make the art, names and layout your own, because borrowed map art is the same IP problem as Phase 1.

How it plays:

- Each node is an NPC with a name, a deck, an AI level (reuse levels 1 to 6), a board spec and a reward order
- Beating a node unlocks the next one, and later nodes use higher AI levels, stronger decks and harder boards
- Each node awards 1 to 3 stars, so there is a reason to replay: 1 for a win, 2 for winning by 3 or more stones, 3 for winning by 5 or more (starting values, to be tuned). Stars arrive in step 15 and are not part of the first slice
- Each win drops the next unowned tile in the node's reward order; once the order is exhausted, wins pay the node's replay gold from the economy table, with a bonus later for beating your best star count
- Nodes are grouped into chapters of 5 to 8, themed by rune or element, and each chapter ends in a boss with a stronger deck
- Every match ends on a result screen with Play again and Back to map, which also fixes the current dead end after a PvC game

What to build:

- [ ] Define campaign node data: id, name, map position, deck, AI level, `BoardSpec`, starting player, reward order, prerequisite node ids (repeat-win gold lives in the economy table)
- [ ] Map screen: a scrolling path where each node shows locked, available or beaten, plus its stars
- [ ] Result screen: win, loss or tie, rewards (a tile or gold), then Play again or Back to map
- [ ] Keep the star rules in one place so the Phase 6 simulation can tune them
- [ ] Save cleared nodes and best stars with the rest of the progress data
- [ ] Chapter structure and boss nodes
- [ ] v1 map art: a simple original background with nodes drawn in SwiftUI; illustrated chapter maps can come in updates

Done when a new player can clear the first node, see the next one unlock, replay to collect that NPC's deck and find it all saved on relaunch.

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

Twelve decisions shape the rules and scope; each has a default so work does not stall waiting on it.

| Decision | Options | Suggested default |
| --- | --- | --- |
| Theme and name | Runes, crystals, constellations, other | Decided: runes theme, name Sigilstone |
| Mismatch rule | Stone breaks into a block, or a +1 / -1 stat swing | Break into a block (matches your target rules); playtest the softer version |
| Ties | Draw, replay, or a tiebreaker rule | Draw: no reward, player retries |
| Turn order | Opponent always first, or coin flip | Coin flip |
| Hands | Visible to both sides, or hidden | Visible for v1, which makes exact AI search possible |
| Business model | Paid, one-time unlock, free | Paid or one-time unlock; no random packs |
| Online PvP | Game Center turn-based, or skip | Skip until after v1 |
| Tile count at launch | Full 80, or fewer | Decided: 52 (basic 10, common 12, uncommon 12, rare 10, epic 8), 32 plain and 20 elemental |
| PvP board and standard deck | Clean board or random stage; plain or elemental commons | Decided: clean board, 5 plain commons for both players; revisit when a board picker exists |
| Free play rewards | Pays nothing, or pays gold | Decided: pays nothing; replay gold is paid on campaign nodes only |
| Campaign star rules | Win only, margin-based, or no stones lost | Margin-based (win, win by 3, win by 5), tuned in the Phase 6 simulation |
| Free play after the campaign | Keep a quick-match mode with any AI level, or campaign only | Keep it; the AI levels already exist, so it costs almost nothing |

Risks to watch:

- App Review rejects the app over leftover Skylanders names, art or audio
- Scope creep: elements, decks and progression are each a full feature, so finish one phase before starting the next
- Unbalanced tiles make decks feel solved; the Phase 6 simulation is the safeguard
- Asset licenses that are unclear or undocumented
- Old Skylanders-derived assets still exist in the archived private repo: keep it private, and check it for forks before deleting it
- Campaign map art is a large asset job: ship v1 with a simple original map and add illustrated chapters in updates
