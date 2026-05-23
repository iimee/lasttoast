# Combat 09 Reduce Ladder Enemy Spacing

## Type
Code artifact

## Context
The combat ladder scene spaces encounter enemies too far apart for quick testing. The requested change is to reduce the distance between enemies by about one third.

## References
- docs/combat.md
- docs/enemies.md
- tasks/review/combat_04_encounter_ladder.md

## Task
Update `res://World/Factory/factory_combat_ladder.tscn` so enemy X spacing is reduced by about one third while preserving encounter order, role composition, start lanes, and combat logic.

## Output
Produce a code artifact with changed paths, behavior impact, and verification notes in this task's `Completion Note` when moving it to `tasks/review/`.

## Do Not Change
- Player/player.gd
- Shared depth-space combat logic
- Depth lock logic
- Depth-aware targeting
- One-shot animation loop settings
- Role behavior, role tuning, or projectile logic

## Acceptance Criteria
- Enemy positions in `factory_combat_ladder.tscn` are closer together by about one third.
- Encounter order remains unchanged.
- No enemy role composition or start lane is changed.

## Completion Note
Completed ladder enemy spacing reduction.

Changed paths:
- `World/Factory/factory_combat_ladder.tscn`

Behavior impact:
- Enemy X positions after the first Charger were compressed toward the first encounter by roughly one third.
- Encounter order, enemy role composition, `start_lane` values, player position, camera limits, role scripts, projectile logic, and depth/combat logic were not changed.
- Example spacing changes: `E02_ChargerA` moved from X `1420` to `1187`, `E03_Charger` from X `2260` to `1747`, and the final trio now spans X `3120` to `3413` instead of X `4320` to `4760`.

Verification notes:
- Static inspection confirmed all requested encounter enemy nodes still exist in order.
- Static inspection confirmed only enemy spawn X positions were intentionally changed for this task.
- In-game verification was not run because no Godot executable is available in this shell.
