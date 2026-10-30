# Sigilstone

[![CI](https://github.com/nickr145/Sigilstone/actions/workflows/ci.yml/badge.svg)](https://github.com/nickr145/Sigilstone/actions/workflows/ci.yml)

A native iOS tile-placement strategy game built with SwiftUI. Two players place tiles on a 3x3 board; each tile has four directional strength values (top, right, bottom, left), and placing a tile captures any adjacent enemy tile whose facing edge value it beats. Whoever controls the most tiles when the board fills up wins.

## Features

- **Player vs. Player** and **Player vs. Computer** modes
- **6 AI difficulty levels**, each a genuinely different strategy rather than just a stat tweak (see below)
- Full capture-chain logic: placing a tile checks all four neighbors and flips ownership of any tile it out-values
- Difficulty-specific piece sets and matching background music per level
- Animated board (GIF-based board background and title-screen animation), instructions screen, and piece/difficulty selection flows

## AI Difficulty Design

Each level is a distinct algorithm, increasing in lookahead depth:

| Level | Strategy |
|-------|----------|
| 1 | Fully random placement |
| 2 | Basic heuristic - prefers corner cells, which are hardest to counter-capture |
| 3 | Greedy - plays the first move it finds that captures at least one enemy tile |
| 4 | Same as Level 3 but evaluates all available cells for a capture before falling back to random |
| 5 | Move simulation - simulates every (cell, piece) combination on a copy of the board and picks the one that captures the most tiles |
| 6 | Simulation with opponent lookahead - for each candidate move, also simulates the best possible reply from the human player and picks the move that maximizes net advantage (captures gained minus the opponent's best counter-capture) |

Level 6 is effectively a shallow minimax: `netScore = simulatedScore - bestOpponentResponse`, which is the same core idea as minimax with a depth-1 search, without the recursive tree.

## Architecture

- **Models** - `Stone` (the tile: 4 directional values + owner) and its capture rule (`canCapture`), plus `PlayerPiecesModel`, which defines the fixed piece sets for each player and difficulty level
- **ViewModels** - `GameViewModel` owns all game state (board, current player, scores, game-over/winner) and every AI strategy function; it's the single source of truth the views observe via `@Published` properties
- **Views** - SwiftUI views for the title screen, difficulty selection, piece selection, the game board itself, instructions, and separate PvP/PvC flow screens

The board is stored as a flat `[Stone?]` array of length 9 (a 3x3 grid), with neighbor lookups done via index arithmetic (`index - 3` for the cell above, `index % 3 != 0` to check for a left neighbor, etc.) rather than a 2D array - a small but deliberate simplification that keeps the capture-checking logic in one place across every AI level.

## Tech Stack

Swift, SwiftUI, Xcode project (no external dependencies)

## Running It

Open `Sigilstone.xcodeproj` in Xcode and run on a simulator or device.

## Running Tests

Any available iPhone simulator works. List them with:

```
xcrun simctl list devices available
```

Then run the tests, substituting a device name from that list for `<device name>`:

```
xcodebuild test -project Sigilstone.xcodeproj -scheme Sigilstone -destination 'platform=iOS Simulator,name=<device name>'
```
