# Ethos Dex

An instance explorer for Roblox executors, in the spirit of Dex and Dex++, built on the Ethos UI library (Fusion).

```lua
loadstring(game:HttpGet("https://github.com/jashxn/EthosDex/releases/latest/download/EthosDex.lua"))()
```

Running it again replaces the open copy. Press **Right Ctrl** to show or hide it; you can change the key in Settings. On touch devices, tap the floating button instead.

The layout follows Dex. A panel docks to the right edge, with the explorer on top and properties below. Drag the line between them to change the split, and drag the panel's left edge to widen it. The script viewer, console, preview and settings open in a separate window that you can move, resize and close.

## Features

- **Explorer.** Studio's class icons and Studio's sort order. Children load only when you open a parent, and the list is virtualized, so very large games stay smooth. Shows nil instances when the executor can list them. Use the crosshair button to click a part in the world and select it.
- **Search.** Matches names, plus `class:Part`, `isa:BasePart`, `tag:Name` and `attr:Name`. It runs in slices, so the game doesn't freeze.
- **Properties.** Read and edit every property from the live API dump, including hidden ones when the executor allows it. Also attributes, tags and multi-select, with live updates.
- **Script viewer.** Decompiles with syntax highlighting, find, copy and save. Uses the executor's decompiler first, then Advanced Decompiler V3, then the lua.expert and Konstant web decompilers. You can pick one in Settings.
- **Console.** Runs Luau with `sel` / `sels` bound to the selection, and shows the game's output.
- **Preview.** Orbit view of models and parts.
- **Actions.** Copy path, rename, cut, copy and paste into (Ctrl+X/C/V), duplicate (Ctrl+D), group, delete, insert, teleport, view (the camera follows it), fire click detectors, proximity prompts and touches, save scripts and bytecode, and save the place or a selection (the executor's `saveinstance`, or SynSaveInstance).
- **Themes.** About 50. On narrow screens, the panel takes the full width and the window fills the screen.
- **Undo.** Ctrl+Z (with the pointer over the panels) undoes deletes, renames, pastes, duplicates, inserts and property edits, up to the last 50.
- **Activity card.** While you view something or pick from the world, a card at the top shows it, with Stop or Cancel right there.
- **Glow.** The selected part or model glows in the world, and whatever the pointer is over in the explorer glows fainter. You can turn either off.
- **Settings.** UI scale, panel opacity, dock side (right or left), row height, text size for the explorer, properties and code, the property name column, the glows and the cursor. Reset puts them back.


## Mouse and keyboard

- **Double-click** (or **Enter**) a script to open it decompiled; anything else expands.
- **Drag** rows onto another row to move them into it (a selected row carries the whole selection). Ctrl+Z puts them back.
- **Middle-click** a part, model or player to view it; middle-click again to stop.
- **Crosshair** picks a part in the world or a piece of the game's UI; the game's UI gets an outline like parts get a glow.
- **Right-click a property**: copy it as code (`obj.Prop = value`), and for object properties like `Parent` or `Adornee`, **Pick in explorer** (click the new value) or **Clear**.
- **Search** compares properties too: `WalkSpeed>16`, `Anchored=true`, `Material=Neon`, `Text~shop` (`= != > < >= <=`, `~` contains). New instances that match show up while the search is open. Clearing it returns to where you were, or to what you picked.
- **Delete** selects the parent afterwards. Copy path indexes by position when a sibling shares the name.
- CFrame properties take 3 numbers (move, keep rotation), 6 (position and orientation in degrees) or 12.

## Executor support

Ethos Dex checks for every executor function before calling it, including the common aliases (`gethui`/`get_hidden_gui`, `request`/`http_request`/`syn.request`, ...), so it runs on any executor. When a function is missing, the feature that needs it is disabled and says why. Settings → Executor shows what this executor supports.

Files go under `workspace/EthosDex/`: settings, the API cache, saved scripts and saved places.

## Building

Needs [Aftman](https://github.com/LPGhatguy/aftman), which installs Lune:

```sh
aftman install
sh scripts/build.sh   # writes dist/EthosDex.lua
```

Pushing a `v*` tag builds the bundle and attaches it to a GitHub release.

The in-game self-checks live in `test/`. Bundle them with `lune run lune/wax.luau bundle input=test.project.json output=dist/EthosDexTests.lua ci-mode=true` and run the output in an executor. It returns the pass and fail counts.

## Credits

Made by **jashan** (Discord `@jasha.n`). Inspired by Moon's Dex, Chillz's Dex++ and VEX Explorer. Built on Fusion and the Ethos UI library.
