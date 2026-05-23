# Combat 06 Fix Projectile Lifetime Signal

## Type
Code artifact

## Context
Static scene validation found that projectile scenes connect `LifetimeTimer.timeout` to `_on_lifetimetimer_timeout`, but their scripts define `_on_lifetime_timeout`. The scripts also connect the correct method in `_ready`, which means the stale scene connection can produce runtime errors when projectile timers expire.

## References
- docs/combat.md
- docs/architecture.md
- tasks/review/combat_05_static_scene_validation.md

## Task
Fix the stale `LifetimeTimer.timeout` scene signal connections for projectile scenes so they point to the existing `_on_lifetime_timeout` method.

## Output
Produce a code artifact with changed paths, behavior impact, and verification notes in this task's `Completion Note` when moving it to `tasks/review/`.

## Do Not Change
- Player/player.gd
- Projectile movement, damage, depth filtering, or lifetime logic
- Shared depth-space combat logic
- One-shot animation loop settings
- Role tuning or encounter layout

## Acceptance Criteria
- `Projectile.tscn`, `BottleFly.tscn`, and `MolotovFly.tscn` no longer reference `_on_lifetimetimer_timeout`.
- Each scene connects `LifetimeTimer.timeout` to `_on_lifetime_timeout`, matching the script method name.
- No projectile behavior values are changed.

## Completion Note
Completed projectile lifetime signal fix.

Changed paths:
- `Combat/Projectiles/Projectile.tscn`
- `Combat/Projectiles/BottleFly.tscn`
- `Combat/Projectiles/MolotovFly.tscn`

Behavior impact:
- `LifetimeTimer.timeout` now points to the existing `_on_lifetime_timeout` method in each projectile script.
- This removes the stale scene-level connection to missing `_on_lifetimetimer_timeout`.
- No projectile movement, damage, collision, depth filtering, lifetime value, animation setting, or skill behavior was changed.

Verification notes:
- Static search confirms `_on_lifetimetimer_timeout` no longer appears in the three projectile scenes.
- Static search confirms each scene now connects to `_on_lifetime_timeout`, matching the method defined in its script.
- Diff check confirms only the three signal connection method names changed.
- In-game verification was not run because no `godot`, `godot4`, or `godot_console` command is available in this shell.
