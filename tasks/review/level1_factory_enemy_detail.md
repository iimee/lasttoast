# Level 1 Factory Enemy Detail

## Type
Design artifact

## Context
Level 1 factory needs a clearer first-pass enemy lineup that supports shared pseudo-depth beat'em up combat without breaking depth-aware targeting, knockback, projectile, or hitbox behavior.

## References
- docs/combat.md
- docs/enemies.md
- docs/factory_enemy_roles.md
- docs/global_enemy_roster.md
- docs/level1_factory_setpieces.md

## Task
Detail the enemy set for Level 1 factory: roles, spacing behavior, depth behavior, attacks, pressure patterns, encounter usage, and constraints for implementation.

## Output
Update the relevant docs with a design artifact for Level 1 factory enemies.

## Do Not Change
- Player/player.gd
- Shared depth-space combat logic
- Depth lock logic
- Depth-aware targeting
- One-shot animation loop settings

## Acceptance Criteria
- Defines gameplay purpose for each Level 1 factory enemy.
- Defines space and positioning behavior in the shared pseudo-depth lane.
- Defines combat constraints and implementation notes.
- Defines encounter usage across the Level 1 factory setpieces.
- Keeps the roster practical for early-game implementation.

## Completion Note
Completed Level 1 factory enemy detail pass. Updated `docs/factory_enemy_roles.md` with first-pass behavior, encounter ramp, implementation constraints, and validation checklist for Rivet Charger, Arc Welder, and Belt Launcher. Updated `docs/global_enemy_roster.md` with factory roster entries, placeholder guidance, and Chief Technologist boss scope. No code, scenes, assets, `Player/player.gd`, shared depth logic, or animation loop settings were changed.
