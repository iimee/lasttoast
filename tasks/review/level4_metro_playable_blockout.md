# Level 4 Metro Playable Blockout

## Type
Code artifact

## Context
Implement the first playable blockout pass for level 4 using `docs/level4_metro_design.md`.

## References
- `docs/level4_metro_design.md`
- `docs/global_enemy_roster.md`
- `docs/gameplay_core.md`
- `docs/combat.md`
- `docs/enemies.md`

## Task
Create a new continuous metro blockout scene under `World/Metro/` with seven internal zones, readable pseudo-depth lanes, placeholder metro enemy roles, player/camera/HUD/skill menu integration, and city transition support.

## Output
Code artifact with changed paths, behavior impact, and verification notes.

## Do Not Change
- `Player/player.gd`
- Shared depth-space combat logic
- One-shot animation loop settings
- Existing level scenes

## Acceptance Criteria
- New scene exists under `World/Metro/`.
- Route contains seven named zones: entrance, turnstiles, platform, first train pass, car interior, tunnel service strip, braking finale.
- The scene has near/center/far depth bands and a long continuous floor collision.
- Placeholder enemies represent Token Clerk, Tunnel Dragger, Signal Worker, and Duty Officer.
- Scene includes player, camera, `Main`, UI labels, and skill menu integration.
- City contains a `METRO` transition that loads the new playable metro blockout, and metro can return to city.
- No changes are made to `Player/player.gd`.

## Completion Note
Changed paths:
- `World/Metro/metro_level_4.tscn`
- `World/main.gd`
- `tasks/review/level4_metro_playable_blockout.md`

Behavior impact:
- Added a new continuous playable metro blockout scene.
- The route contains seven named internal zones: entrance, turnstiles, platform, first train pass, car interior, tunnel service strip, and braking finale.
- Added readable near/center/far depth bands, long floor collision, metro setpiece markers, platform-edge/train/door/spark/wind read markers, and placeholder enemies for Token Clerk, Tunnel Dragger, Signal Worker, and Duty Officer.
- Included player, camera, `Main`, UI labels, and `SkillSelectMenu` integration matching the existing blockout pattern.
- Added `SCENE_METRO`, a city `METRO` transition, and a metro return-to-city transition in `World/main.gd`.
- Did not modify `Player/player.gd`, shared combat/depth logic, or one-shot animation loop settings.

Verification notes:
- Confirmed this was the single task read from `tasks/ready/`.
- Confirmed the new scene contains all seven `Zone_0*` nodes, expected placeholder enemy role names, player, camera, skill menu, `Main`, and HUD labels by text search.
- Confirmed `World/main.gd` contains `SCENE_METRO`, `ExitToMetro`, and metro return handling.
- Could not run Godot headless validation because no `godot`/`godot4` executable is available in PATH in this shell.
