# Level 3 Bridge Design And Blockout

## Type
Design artifact, then code artifact

## Context
Build the third main level from `LAST_TOAST_scenario_v2.md`: мокрый речной мост, обрушение, грузовик без водителя, ветер, дождь, ограждения, черная вода and the boss `Инженер`.

## References
- `LAST_TOAST_scenario_v2.md`
- `docs/scenario_russia_90s_adaptation.md`
- `docs/gameplay_core.md`
- `docs/combat.md`
- `docs/enemies.md`
- `docs/art_style_guide.md`
- `docs/asset_pipeline.md`

## Task
Create an executable task output for the bridge level: route design and minimal playable blockout plan under `World/Bridge/`. The route must make the bridge feel unstable while preserving the shared pseudo-depth combat field.

Include new enemies:
- `Cable Hook`: mid-range enemy who pulls along one readable depth line, never across hidden overlap.
- `Raincoat Guard`: shielded blocker who anchors near railings and creates temporary side pressure.
- `Headlight Sprinter`: fast enemy telegraphed by headlights/reflections before a straight-line rush.
- Boss `Инженер`: uses diagrams, cable zones, unstable panels, and precise but readable attacks.

Include background generation requirements:
- Create an art request for a layered bridge background in `assets/requests/bridge_background.md`.
- Generated candidates must land in `assets/incoming/bridge/`.
- Background must show wet asphalt, chain fences, dim lamps, river darkness, rain streaks, broken span hints, and distant city lights.

## Output
Design artifact with gameplay purpose, space/positioning behavior, constraints, acceptance criteria, changed paths, behavior impact, and verification notes. If code is implemented in the same task, include changed Godot paths separately.

## Do Not Change
- `Player/player.gd`
- Shared depth-space combat logic
- One-shot animation loop settings
- Existing factory level scenes

## Acceptance Criteria
- Bridge route has at least 6 named internal zones: approach road, first railing, truck lane, service shoulder, cracked span, central break.
- Each zone defines safe depth bands, collapse/hazard timing, enemy pressure, and a route turn.
- Truck/headlight events are telegraphed and never act as instant death.
- New enemy roles define combat role, preferred spacing, attack range, movement pressure, and counterplay.
- Boss `Инженер` tests positioning around cables and panels without attacks that ignore depth overlap.
- Background generation request includes size, palette direction, layer plan, expected output paths, and readability constraints.
- No changes are made to `Player/player.gd`.

## Completion Note
Changed paths:
- `docs/level3_bridge_design.md`
- `assets/requests/bridge_background.md`
- `tasks/review/level3_bridge_design_and_blockout.md`

Behavior impact:
- Added a bridge level design/blockout artifact with six named route zones, safe depth bands, hazard timing, enemy pressure, and route turns.
- Added/linked the bridge background request created by the background pipeline task.
- Kept the output as design/art planning only; no Godot scenes or code were changed because the worktree already contains unrelated scene/enemy changes.

Verification notes:
- Read this single task from `tasks/ready/` before implementation.
- Read scenario bridge references and used `docs/global_enemy_roster.md` roles.
- Verified the design requires truck, cable, collapse, and boss attacks to be telegraphed by lane and never ignore depth overlap.
