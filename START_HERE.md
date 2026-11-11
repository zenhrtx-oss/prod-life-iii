# Prod Life III: start here

Prod Life III is a Roblox game about a music producer's career. Making beats is how you play, and a BitLife-style life layer (walk-ins, phone cards, fame) sits around it. This repo is a copy of the game's working folder. Zenji refreshes it from the original. It's here to read for now: please don't push to it, because anything pushed here doesn't reach the game and blocks Zenji's next refresh.

## The language is Luau

Roblox Studio runs **Luau**, a typed dialect of Lua (https://luau.org). Only the helper tools in `tools/` are Python.

## Where things are

- `src/` holds the source of truth, laid out by Roblox service:
  - `src/ReplicatedStorage/OK/`: shared modules (`Modules/`), game systems (`Systems/`), card data (`Data/`) and `Config.lua`
  - `src/ServerScriptService/OK/`: server services (saves, monitors) and `Main.server.lua`
  - `src/StarterPlayer/StarterPlayerScripts/OK/`: client scripts
- **The beat maker:**
  - `Modules/DAWEngine.lua` (playback)
  - `Modules/DAWUI.lua` (the screen)
  - `Modules/DAWConfig.lua` (tracks, sounds, kits, voices)
  - `Modules/PianoRoll.lua` (the keys)
  - `Systems/DAW.lua` (the server side)
  - `StarterPlayer/StarterPlayerScripts/OK/DAWClient.client.lua`
- **Kits and gear:** `Systems/Gear.lua` and `Config.Gear`. Today two drum kits (TAPE, IRON) swap the kick/snare/clap/hat sounds, and the 808 is shared.
- `build/`: re-runnable Luau scripts that build the place, plus the Studio tests (`t*_check.lua`, `t*_play_*.lua`).
- `spec/`: pure-logic tests run with the `luau` command line (`tools/spec.sh`).
- `tools/`: `sync.py` writes `src/` into the open Studio place; `test.py` runs every check.
- **Docs:**
  - `README.md` (what each milestone added, how the systems work)
  - `plans/` and `specs/` (designs and build plans)
  - `research/`
  - The beat maker upgrade already on the launch list is "Task 5f" in `plans/2026-11-05-wave3-stakes.md`.

## How code gets into the game

The game isn't built with Rojo. Claude Code sessions edit `src/`. Then `tools/sync.py` writes it into the place open in Roblox Studio, through Roblox's Studio MCP, and `tools/test.py` runs the checks inside Studio. Several Claude sessions share the live place, so nobody edits it without coordinating first.

## Running it

Open the copy of the place Zenji sends you (a `.rbxl` file) in Roblox Studio and press Play. Editing scripts inside your copy is fine for experiments. Those changes don't flow back here or into the live game.

## For now, please don't

- connect to or edit the live place
- upload sounds or images to Roblox
- run scripts from free models
