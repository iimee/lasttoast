# Combat 01 Charger Role

## Type
Code artifact

## Context
The baseline `hobo1` enemy contract must be stable before role work starts. The first factory role should be the simplest readable melee pressure enemy: a Charger that teaches same-depth attack alignment.

## References
- docs/combat.md
- docs/enemies.md
- docs/architecture.md
- docs/factory_enemy_roles.md
- tasks/review/combat_00_baseline_audit.md

## Task
Build or configure the first playable Charger role using existing `hobo1` behavior patterns, preferring `hobo1_rusher` or `hobo1_bruiser` if they already fit the role.

The Charger should:
- Approach the player directly.
- Realign to the player's depth before attacking.
- Use a short, close-range frontal melee attack.
- Miss if the player leaves valid depth before the active hit.
- Recover cleanly after hit, miss, hurt, or death.

## Output
Produce a code artifact with changed paths, behavior impact, and verification notes in this task's `Completion Note` when moving it to `tasks/review/`.

## Do Not Change
- Player/player.gd
- Shared depth-space combat logic
- Depth lock logic
- Depth-aware targeting
- One-shot animation loop settings
- Launcher, Welder, boss, or mixed encounter behavior

## Acceptance Criteria
- One Charger scene or variant is usable as the first factory melee pressure enemy.
- Charger cannot damage the player across invalid depth.
- Charger has readable approach, attack startup, active hit, and recovery behavior using existing presentation where possible.
- Player can damage, interrupt, knock back, and kill the Charger without stuck states.
- Verification notes cover same-depth hit, off-depth miss, hurt recovery, and death cleanup.

## Completion Note
Completed the first playable Charger role as a minimal scene alias over the existing rusher behavior.

Changed paths:
- `Enemies/hobo1/hobo1_charger.tscn`

Behavior impact:
- Adds an explicit `hobo1_charger` scene for the first factory melee pressure role.
- The scene instances `hobo1_rusher.tscn`, so it reuses the existing `hobo1` combat contract and rusher tuning instead of introducing a new AI path.
- The chosen behavior approaches directly, keeps `prefer_player_back = false`, uses short melee range through `rusher_attack_range_px = 24.0`, follows player depth from a wider distance through `rusher_depth_follow_distance_px = 240.0`, and inherits baseline depth-aware hit validation, hurt recovery, and death cleanup from `hobo1.gd`.

Verification notes:
- Static verification confirmed the Charger scene resolves to `hobo1_rusher.tscn`.
- Static verification confirmed the inherited enemy attack path checks `_is_target_in_depth_reach` before applying player damage.
- Static verification confirmed `HURT`, `ATTACK`, and `DEAD` transitions are inherited from the audited baseline.
- In-game verification was not run because no `godot`, `godot4`, or `godot_console` command is available in this shell. The next playable check should confirm same-depth hit, off-depth miss, hurt recovery, and death cleanup in the editor/runtime.
