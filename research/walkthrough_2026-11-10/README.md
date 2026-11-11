# Walkthrough page for OK and Shareef (2026-11-10)

Published at https://claude.ai/artifact/WtZ9jdXmzpnq4X8Y5uyNn1 (private until shared). Republish `site/walkthrough.html` with the other files in `site/` as supporting files, passing that URL.

- `site/data.js` is generated from the game's own data: every card and follow-up in `src/ReplicatedStorage/OK/Data/WalkIns.lua` (127), plus Config and the artist requests. Regenerate after card changes: copy WalkIns.lua, Artists.lua and Config.lua next to `extract/dump.luau` as `.luau` (stub Color3 as the script header shows), run `luau dump.luau > raw.json`, then `build_data.py`.
- `site/engine.js` is a JS port of WalkInRules, CareerRules.ColdStep and BriefCheck. `extract/check.luau` + `check.js` compare it with the Luau rules (7,944 comparisons matched on 11-10). `smoke.js` plays random careers.
- The page's notes live in its database: collections `decisions`, `ideas`, `cardnotes`, `rooms` (doc `draft`), `meeting` (doc `notes`). Read them with ArtifactData.
- The page is a model for explaining the game. It never touches the place or the game code.
