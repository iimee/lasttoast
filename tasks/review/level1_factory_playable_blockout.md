# Level 1 Factory Playable Blockout

## Type
Code artifact

## Context
Implement the first playable pass of level 1 based on `docs/level1_factory_setpieces.md`, `docs/locations.md`, `docs/gameplay_core.md`, `docs/combat.md`, and `docs/factory_enemy_roles.md`.

## References
- `docs/level1_factory_setpieces.md`
- `docs/locations.md`
- `docs/gameplay_core.md`
- `docs/combat.md`
- `docs/factory_enemy_roles.md`

## Task
Create a minimal playable factory level scene that communicates the level 1 route, shared pseudo-depth combat lanes, readable setpiece beats, and factory enemy pressure without changing player code or shared combat logic.

## Output
Code artifact with changed paths, behavior impact, and verification notes.

## Do Not Change
- `Player/player.gd`
- Shared depth-space combat logic
- One-shot animation looping behavior

## Acceptance Criteria
- Level 1 exists as a Godot scene under `World/Factory/`.
- The route has multiple factory setpiece beats and readable near/center/far depth bands.
- The scene includes player, camera, HUD/skill menu integration, and factory-role enemy placeholders using existing enemy scenes.
- The level is reachable from existing scene transition logic and can return to the city.
- No changes are made to `Player/player.gd`.

## Completion Note
Changed paths:
- `World/Factory/factory_level_1.tscn`
- `World/main.gd`
- `tasks/review/level1_factory_playable_blockout.md`

Behavior impact:
- Added a playable level 1 factory blockout scene with player, camera, HUD labels, skill menu integration, readable near/center/far depth bands, factory setpiece markers, and existing enemy-role placeholders.
- Extended existing scene transition setup so the city exposes a `FACTORY` exit and the factory level exposes a `CITY` return exit.
- Did not modify `Player/player.gd`, shared combat hitbox logic, projectile logic, lane/depth logic, or animation loop settings.

Verification notes:
- Confirmed the task file was the single task read from `tasks/ready/`.
- Confirmed the factory scene contains the expected player, camera, `Main`, skill menu, and enemy placeholder nodes by text search.
- Could not run Godot headless validation because no `godot`/`godot4` executable is available in PATH in this shell.
