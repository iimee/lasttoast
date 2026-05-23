# Combat 02 Launcher Role

## Type
Code artifact

## Context
After the Charger is stable, the next factory role is a simple backline projectile enemy. The Launcher should teach fixed depth-line projectile pressure without adding a new global combat system.

## References
- docs/combat.md
- docs/enemies.md
- docs/architecture.md
- docs/factory_enemy_roles.md
- tasks/review/combat_00_baseline_audit.md
- tasks/review/combat_01_charger_role.md

## Task
Build or configure the first playable Belt Launcher role using existing enemy and projectile conventions.

The Launcher should:
- Keep mid-to-long spacing when possible.
- Telegraph before firing.
- Fire a projectile along its current depth line.
- Lock projectile depth at release instead of homing after the player.
- Enter a reload/recovery gap that the player can punish.

## Output
Produce a code artifact with changed paths, behavior impact, and verification notes in this task's `Completion Note` when moving it to `tasks/review/`.

## Do Not Change
- Player/player.gd
- Shared depth-space combat logic
- Depth lock logic
- Depth-aware targeting
- One-shot animation loop settings
- Charger behavior except for required compatibility fixes
- Welder, boss, or mixed encounter behavior

## Acceptance Criteria
- One Launcher scene or variant is usable as the first factory ranged pressure enemy.
- Projectile damage applies only on valid spatial/depth overlap.
- Projectile keeps its release depth and does not track depth after firing.
- Player can avoid the shot by changing depth and can punish the reload gap.
- Verification notes cover same-depth hit, off-depth dodge, reload punish, and death cleanup.

## Completion Note
Completed the first playable Belt Launcher role as a focused `hobo1` variant that reuses the existing enemy runtime and projectile contract.

Changed paths:
- `Enemies/hobo1/hobo1_launcher.gd`
- `Enemies/hobo1/hobo1_launcher.tscn`

Behavior impact:
- Adds a `hobo1_launcher` scene for the first factory ranged pressure role.
- The Launcher keeps a preferred mid-range X spacing when chasing, aligns depth using inherited `LaneBody` follow behavior, then uses the inherited `attack` animation as a telegraph.
- The Launcher fires `Combat/Projectiles/Projectile.tscn` after `launcher_telegraph_sec`, sets the projectile to target the `Player` group, limits collision to the player layer, disables smoke-ring dash combo behavior, and assigns projectile `depth_y` from the Launcher's current `lane_body.depth_y` at release.
- The shot does not retarget after release: direction and depth are captured when firing.
- After firing, the Launcher remains in a short recovery window and uses `launcher_reload_sec` as the punishable reload cadence.

Verification notes:
- Static verification confirmed `hobo1_launcher.tscn` instances `hobo1.tscn` with `hobo1_launcher.gd`.
- Static verification confirmed the projectile is configured with `enemy_group = "Player"`, `ignore_groups = ["Enemy", "attack"]`, `collision_mask = Layers.PLAYER`, and `dash_combo_enabled = false`.
- Static verification confirmed projectile depth is set from `lane_body.depth_y` before `setup`, so off-depth movement should avoid the shot.
- Static verification confirmed damage, hurt, death, and cleanup remain inherited from the audited `hobo1` baseline.
- In-game verification was not run because no `godot`, `godot4`, or `godot_console` command is available in this shell. The next runtime check should confirm same-depth projectile hit, off-depth dodge, reload punish, and death cleanup.
