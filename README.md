# Ethos Dex

An instance explorer for Roblox executors, in the spirit of Dex and Dex++, built on the Ethos UI library (Fusion).

```lua
loadstring(game:HttpGet("https://github.com/jashxn/EthosDex/releases/latest/download/EthosDex.lua"))()
```

Running it again replaces the open copy. Press **Right Ctrl** to show or hide it; you can change the key in Settings. On touch devices, tap the floating button instead.

## Features

- **Explorer.** Studio's class icons and Studio's sort order. Children load only when you open a parent, and the list is virtualized, so very large games stay smooth. Shows nil instances when the executor can list them.
- **Search.** Matches names, plus `class:Part`, `isa:BasePart`, `tag:Name` and `attr:Name`. It runs in slices, so the game doesn't freeze.
- **Properties.** Read and edit every property from the live API dump, including hidden ones when the executor allows it. Also attributes, tags and multi-select, with live updates.
- **Script viewer.** Decompiles with syntax highlighting, find, copy and save. Uses the executor's decompiler first, then Advanced Decompiler V3, then Konstant. You can pick one in Settings.
- **Console.** Runs Luau with `sel` / `sels` bound to the selection, and shows the game's output.
- **Preview.** Orbit view of models and parts.
- **Actions.** Copy path, rename, duplicate, group, delete, insert, teleport, fire click detectors, proximity prompts and touches, save scripts and bytecode, and save the place or a selection (the executor's `saveinstance`, or SynSaveInstance).
- **Window and themes.** About 50 themes. The window is resizable and can be maximized. It switches to a phone layout on narrow screens.

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

Made by **jashan** (Discord `@jasha.n`). Inspired by Moon's Dex and Chillz's Dex++. Built on Fusion and the Ethos UI library.
