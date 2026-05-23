# Combat 10 Sync Ladder Spacing

## Type
Code artifact

## Context
The combat ladder spacing note says enemy positions were compressed, but `res://World/Factory/factory_combat_ladder.tscn` currently contains the older wider X positions. The ladder needs to match the intended closer spacing before any feel tuning or playtest notes are trusted.

## References
- docs/combat.md
- docs/enemies.md
- docs/factory_enemy_roles.md
- tasks/review/combat_09_reduce_ladder_enemy_spacing.md

## Task
Update only enemy spawn X positions in `res://World/Factory/factory_combat_ladder.tscn` to restore the reduced encounter spacing:
- `E02_ChargerA`: X `1187`
- `E02_ChargerB`: X `1240`
- `E03_Charger`: X `1747`
- `E03_Launcher`: X `1933`
- `E04_Charger`: X `2387`
- `E04_Welder`: X `2573`
- `E05_Charger`: X `3120`
- `E05_Launcher`: X `3293`
- `E05_Welder`: X `3413`

Keep all Y positions unchanged.

## Output
Produce a code artifact with changed paths, behavior impact, and verification notes in this task's `Completion Note` when moving it to `tasks/review/`.

## Do Not Change
- `Player/player.gd`
- Shared depth-space combat logic
- Depth lock logic
- Depth-aware targeting
- One-shot animation loop settings
- Enemy role behavior or tuning values
- Encounter role composition
- `start_lane` values

## Acceptance Criteria
- The listed enemy nodes use the exact X positions above.
- `E01_Charger`, `Player`, camera, labels, role scenes, and `start_lane` values are unchanged.
- No combat script or enemy role script is changed.

## Completion Note
Completed ladder spacing sync.

Changed paths:
- `World/Factory/factory_combat_ladder.tscn`

Behavior impact:
- Restored the reduced enemy X positions requested for the combat ladder.
- The updated spawn X positions are `E02_ChargerA=1187`, `E02_ChargerB=1240`, `E03_Charger=1747`, `E03_Launcher=1933`, `E04_Charger=2387`, `E04_Welder=2573`, `E05_Charger=3120`, `E05_Launcher=3293`, and `E05_Welder=3413`.
- Enemy Y positions, encounter order, role composition, `start_lane` values, player position, camera, labels, role scripts, projectile logic, and shared depth/combat logic were not changed.

Verification notes:
- Static inspection confirmed each listed enemy node now has the exact requested X position.
- Static inspection confirmed `E01_Charger`, `Player`, camera, labels, and `start_lane` values remain present and unchanged by this task.
- In-game verification was not run because no Godot executable is available in this shell.
