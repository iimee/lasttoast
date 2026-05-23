# Level 4 Metro Design And Blockout

## Type
Design artifact, then code artifact

## Context
Build the fourth main level from `LAST_TOAST_scenario_v2.md`: метро, поезд без контроля, пустая станция, служебный свет, тоннельный гул and the boss `Дежурный`.

## References
- `LAST_TOAST_scenario_v2.md`
- `docs/scenario_russia_90s_adaptation.md`
- `docs/gameplay_core.md`
- `docs/combat.md`
- `docs/enemies.md`
- `docs/art_style_guide.md`
- `docs/asset_pipeline.md`

## Task
Create an executable task output for the metro level: route design and minimal playable blockout plan under `World/Metro/`. The level must move between platform, car, tunnel-adjacent areas, and roof/maintenance beats while keeping one continuous readable combat space.

Include new enemies:
- `Token Clerk`: ranged/control enemy who marks a depth lane with ticket-token projectiles.
- `Tunnel Dragger`: close enemy who advances from darkness with strong startup and slow recovery.
- `Signal Worker`: support enemy who changes light states and opens temporary hazard windows.
- Boss `Дежурный`: controls train rhythm, announcements, doors, and platform timing.

Include background generation requirements:
- Create an art request for a layered metro background in `assets/requests/metro_background.md`.
- Generated candidates must land in `assets/incoming/metro/`.
- Background must show faded ads, flickering route board, tunnel mouth, platform edge, service lamps, old tile, and train silhouettes.

## Output
Design artifact with gameplay purpose, space/positioning behavior, constraints, acceptance criteria, changed paths, behavior impact, and verification notes. If code is implemented in the same task, include changed Godot paths separately.

## Do Not Change
- `Player/player.gd`
- Shared depth-space combat logic
- One-shot animation loop settings
- Existing factory level scenes

## Acceptance Criteria
- Metro route has at least 7 named internal zones: entrance, turnstiles, platform, first train pass, car interior, tunnel service strip, braking finale.
- Platform edge is readable but not used as cheap instant death.
- Train events, doors, sparks, and wind are telegraphed with safe timing windows.
- New enemy roles define combat role, preferred spacing, attack range, movement pressure, and counterplay.
- Boss `Дежурный` uses station systems in depth-aware patterns.
- Background generation request includes size, palette direction, layer plan, expected output paths, and readability constraints.
- No changes are made to `Player/player.gd`.

## Completion Note
Changed paths:
- `docs/level4_metro_design.md`
- `assets/requests/metro_background.md`
- `tasks/review/level4_metro_design_and_blockout.md`

Behavior impact:
- Added a metro level design/blockout artifact with seven named internal zones, route turns, train/platform hazards, enemy compositions, and boss phases.
- Added/linked the metro background request created by the background pipeline task.
- Kept the output as design/art planning only; no Godot scenes or code were changed because the worktree already contains unrelated scene/enemy changes.

Verification notes:
- Read this single task from `tasks/ready/` before implementation.
- Read scenario metro references and used `docs/global_enemy_roster.md` roles.
- Verified the design treats platform edge, train passes, doors, sparks, and wind as telegraphed lane hazards with recoverable windows.
