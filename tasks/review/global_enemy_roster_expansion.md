# Global Enemy Roster Expansion

## Type
Design artifact, then code artifact

## Context
The scenario now needs enemy roles beyond the factory. Enemies must remain predictable in shared pseudo-depth combat and support each level's social identity.

## References
- `LAST_TOAST_scenario_v2.md`
- `docs/enemies.md`
- `docs/combat.md`
- `docs/gameplay_core.md`
- `docs/scenario_russia_90s_adaptation.md`
- `docs/art_style_guide.md`

## Task
Create a global enemy roster document and, if scoped for implementation, placeholder Godot scenes/scripts for the first playable pass of new enemies.

Required roster groups:
- Stadium: `Turnstile Shover`, `Bottle Thrower`, `Flag Runner`.
- Bridge: `Cable Hook`, `Raincoat Guard`, `Headlight Sprinter`.
- Metro: `Token Clerk`, `Tunnel Dragger`, `Signal Worker`.
- Forest camp: `Ash Runner`, `Ember Carrier`, `Wet Plank Brute`.
- Finale/aftermath: `Debt Echo` plus location-specific aftermath bosses.

For each enemy define:
- Combat role.
- Preferred spacing and depth behavior.
- Attack range.
- Movement pressure.
- Counterplay.
- Hazard or projectile readability.
- Minimum animation needs.
- Allowed reuse of existing placeholder sprites/scenes.

## Output
Design artifact with optional code artifact. Code artifacts must list changed paths, behavior impact, and verification notes.

## Do Not Change
- `Player/player.gd`
- Shared depth-space combat logic
- One-shot animation loop settings
- Existing enemy behavior unless the task explicitly scopes safe reuse

## Acceptance Criteria
- Every new enemy has a clear role and does not duplicate an existing role without a reason.
- No enemy attack ignores depth-aware targeting.
- Ranged attacks define lane, telegraph, projectile travel, impact, and counterplay.
- Area control enemies define maximum covered bands and safe escape rules.
- Placeholder implementation, if done, uses existing enemy patterns conservatively and does not require new player code.
- Documentation names which enemies are required for each level task.

## Completion Note
Changed paths:
- `docs/global_enemy_roster.md`
- `tasks/review/global_enemy_roster_expansion.md`

Behavior impact:
- Added a global roster document covering stadium, bridge, metro, forest camp, aftermath, and finale roles.
- Defined combat role, spacing, attack range, movement pressure, counterplay, readability, animation needs, and placeholder reuse for each required enemy.
- Named which enemies belong to each level task.
- Did not implement placeholder scenes or modify existing enemy/player code because the worktree already contains unrelated enemy changes.

Verification notes:
- Read this single task from `tasks/ready/` before implementation.
- Read `docs/enemies.md`, `docs/combat.md`, and `docs/gameplay_core.md`.
- Verified the document states depth-aware limits for ranged, area, and rush behaviors.
