# User brief (verbatim, 2026-10-22)

The goal is to build a fully playable Roblox music universe around wegonebeok, not just a hangout or a set for promotional content.
The studio should be our starting point, but everything needs to be designed so we can eventually expand into a full music-industry game.

1. Build the studio as our first playable hub. Make it visually impressive, immersive, and highly detailed. Dark underground aesthetic, warm lighting, neon accents, realistic recording equipment, a vocal booth, a lounge, and interactive spaces.
2. Design for future gameplay. Eventually we're adding an advanced beatmaking DAW, studio tycoon progression, customizable studios, beat battles, artist collaborations, producer profiles, real-world music credits, and networking. Structure the project so these systems can be added without rebuilding everything.
3. Make the environment interactive. I don't want a beautiful room where nothing happens. Players should be able to interact with the equipment, use computers, explore, sit down, and access music-related features. Start with simple working interactions rather than decorative buttons.
4. Keep the existing models as references. Inspect what's already in the place and identify anything worth reusing. Don't run untrusted free-model scripts. Preserve the original in a backup, then create a clean version using vetted assets and optimized geometry.
5. Prioritize visual quality and performance. I want this to feel like a genuinely impressive Roblox experience, not a basic blocky studio. Use references from high-quality Roblox games and professional recording studios while keeping mobile performance in mind.
6. Build the architecture properly. Use modular systems and organize the project so Claude Code can continue adding gameplay, interfaces, multiplayer features, and external integrations.

For the first version, prioritize one incredible, functional OK studio rather than building an entire city of unfinished features.
Make reasonable creative decisions. Save the original place and preserve working versions throughout development.
The long-term goal is a Roblox music ecosystem where users can create music, collaborate, build careers, and connect their real-world music identities.

# Context for reviewers
- Platform: Roblox Studio 0.744 on macOS, built through the built-in Studio MCP (execute_luau). Luau cannot set Lighting.Technology; images cannot be uploaded safely (the account was moderated once for album art); no audio assets are licensed yet.
- The place is unsaved in the running Studio session until the user saves it.
- The four original free models (a music studio, two PC desks, a neon room) are preserved in ServerStorage.OK_Backup_2026-10-22 with scripts disabled; none of their geometry was reused in v1.
