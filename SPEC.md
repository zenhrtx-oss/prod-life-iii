# OK Studio: design spec (v1, 2026-10-22)

## Intent
A fully playable Roblox music universe around the producer OK (@wegonebeok). Version 1 is one incredible, functional studio hub: dark underground, warm light, neon accents, real equipment, a vocal booth, a lounge, and interactions that work. Every system is modular so a DAW, tycoon progression, customizable studios, beat battles, collaborations, producer profiles, real-world credits and networking can be added without rebuilding.

## Goals / non-goals / anti-goals
- Goals: visually impressive on desktop and phone; every piece of equipment does something simple and real; clean architecture a future session can extend; versions preserved.
- Non-goals (v1): audio playback, a working DAW, economy, DataStore-backed progression beyond a stub, multiplayer features beyond what Roblox gives for free.
- Anti-goals: free-model scripts running anywhere; uploaded images that Roblox moderation could flag; a pretty room where nothing happens; a part count that stutters on mobile.

## Constraints (global)
- Build from primitives plus a few vetted Creator Store props. Every inserted asset is script-stripped before it stays.
- Part budget for the build: 6,000 parts. Lights: at most 24 PointLight/SpotLight/SurfaceLight. Lighting.Technology = ShadowMap.
- No image uploads in v1. All signage, posters, plaques and screens are SurfaceGui text, so nothing goes through image moderation.
- No music or audio assets unless OK's team supplies files and permission.
- Credits shown in-world come only from rows marked Confirmed in the campaign research (see Data below).
- The originals already in the place are preserved untouched in ServerStorage.OK_Backup_2026-10-22 with scripts disabled, and the user saves the place to the "test" experience at each milestone.

## Layout (studs; floor top at y=0; x runs west to east)
| Space | X range | Z range | Ceiling | Floor | Walls |
|---|---|---|---|---|---|
| Entry corridor | 0 to 12 | 0 to 10 | 10 | Concrete, dark | Concrete 30/30/32, neon strip at ceiling line |
| Lounge | 12 to 44 | -12 to 12 | 12 | WoodPlanks, dark walnut | Concrete plus one Brick accent wall (north), neon sign |
| Control room | 44 to 80 | -12 to 12 | 12 | Fabric carpet, charcoal | Concrete with acoustic panel strips (Fabric, dark maroon) |
| Vocal booth | 80 to 94 | -6 to 6 | 10 | Fabric carpet | Concrete with foam panel grid on inner faces |

Openings: corridor to lounge at x=12, z 3 to 7 (double door, static open frame); lounge to control room at x=44, z -3 to 3 (sliding door, interactive); control room to booth at x=80, z 7 to 10 (hinged door, static open); booth window at x=80, z -6 to 6, y 3 to 8 (glass, Transparency 0.35). Spawn at (6, 0.5, 5) facing +X.

## Contents
- Control room: mixing console desk (knob rows, faders, LED meter columns), two monitors with "OK STUDIO OS" screens, MIDI keyboard, pair of studio monitors on stands, two 8-unit racks with LED dots, producer chair (Seat), leather couch (Seats) at the back, rug, side table with warm lamp, neon "OK" sign over the booth window, plaques.
- Vocal booth: mic on stand with pop filter (Creator Store mic allowed), music stand, headphones on hook, REC sign over the window (neon red, text), warm lamp, foam panel grid.
- Lounge: L-shaped sofa (Seats), coffee table, record crates, bar counter with three stools (Seats), TV wall screen (text, cycles), credits wall with plaques, neon "WEGONEBEOK" sign, two plants, posters as typography.
- Corridor: entry sign "OK STUDIO" with "est. 2023", floor arrows, neon strip.

## Interactions (v1, all working)
1. Seats: sofa, couch, chair, stools.
2. Computer (control room monitors): ProximityPrompt "Use computer" opens the OK panel with tabs Credits, Sessions ("DAW coming soon" and what it will do), Profile (player name, level from DataService stub, visits).
3. Console: "Power console" toggles LED meters animating and the studio monitors pulsing. State lives on an attribute; server owns it.
4. Mic: "Start take" turns the REC sign on and the booth lamp red for 8 seconds, then off.
5. Light switch (control room wall): toggles presets Warm and Neon (lamp colors, neon strip colors, Lighting ambient).
6. Sliding door lounge/control room: "Open" or "Close" tweens the panel.
7. Credits wall: "Read credits" opens the Credits tab.
8. TV wall: "Change screen" cycles Credits highlights, Coming soon, Profile.

## Architecture (inside the place)
- Workspace.OKStudio (Model): Shell, ControlRoom, VocalBooth, Lounge, Corridor, Lighting, Props, Interactables. Interactables carry CollectionService tag `OK_Interactable` and attributes `Kind` (Computer|Console|Mic|LightSwitch|Door|CreditsWall|TV) and `Title`.
- ReplicatedStorage.OK: Config (ModuleScript), Data.Credits (ModuleScript), Remotes (InteractionEvent RemoteEvent, ProfileFunction RemoteFunction), Modules.UITheme, Systems folder with stubs DAW, Tycoon, Profiles, BeatBattles, Collab, Networking, each `{Enabled=false, Version=0, Init=function(ctx) end}` with a doc comment of its intended interface, plus Systems.README.
- ServerScriptService.OK: Main (Script) that requires Services.InteractionService, Services.LightingService, Services.DataService (DataStore "OKStudio_v1", pcall-wrapped, falls back to session memory in Studio).
- StarterPlayer.StarterPlayerScripts.OK.ClientMain (LocalScript) and StarterGui.OK_UI (ScreenGui, hidden panel with tabs).
- ServerStorage: OK_Backup_2026-10-22 (originals, scripts disabled), OK_Versions (a clone of Workspace.OKStudio after each milestone, named v1_shell, v2_rooms, v3_interactions, v4_polish), OK_Reference (vetted props).
- Build scripts live outside Roblox in OK ROBLOX/roblox_studio_notes/ok_studio/build/*.lua and are re-runnable: each starts by removing what it previously built, so the whole studio can be regenerated into an empty place.

## Data: credits shown in v1 (Confirmed in campaign research)
Nettspend: Packs (feat. Duwap Kaine) 2023; Benihana 2023; Otw (feat. xaviersobased) 2023; wake up (feat. OsamaSon) 2023; 2024 Freestyle 2023; nothing like uuu 2024; F*CK SWAG 2024 (video by Lyrical Lemonade); BAD ASS F*CKING KID 2024, nine tracks: Leader (with Kenny Beats), Project Pat, Tyla, A$AP, Skipping Class, Shut Up, Birdbox, Perc Soda, LAUGHIN; "<3 me" on early life crisis 2026 (with OTW). OsamaSon & Nettspend: withdrawals 2024. fakemink: Music and Me, Crush, 101 (with DJ Phat). Sources: Apple Music label-fed credits as compiled in ok_nettspend_relationship/research_notes/releases_credits.md and ok_carousel_campaign/.../discography_credit_matrix.csv.

## Visual direction
Dark underground: near-black concrete, dark walnut, charcoal carpet, one brick wall. Warm lamps (255,190,120) as the key light, neon accents in two colors only (electric blue 0,170,255 and hot pink 255,60,160) used on strips, signs and LED rows. Bloom low, slight warm color correction, night sky, fog so nothing outside reads. Typography on screens and plaques: bold uppercase, generous letter spacing.

## Left to the builder
Exact knob counts, sofa proportions, plant shapes, plaque wording beyond the credits list, prompt hold durations, panel styling details.
