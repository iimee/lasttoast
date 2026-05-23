# Level 2 Stadium Design And Blockout

## Type
Design artifact, then code artifact

## Context
Build the second main level from `LAST_TOAST_scenario_v2.md`: районный стадион, срыв мероприятия, давление толпы, бетонные трибуны, прожекторы, подземные проходы and the boss `Чемпион`.

## References
- `LAST_TOAST_scenario_v2.md`
- `docs/scenario_russia_90s_adaptation.md`
- `docs/gameplay_core.md`
- `docs/combat.md`
- `docs/enemies.md`
- `docs/art_style_guide.md`
- `docs/asset_pipeline.md`

## Task
Create an executable task output for the stadium level: a readable route design and a minimal playable blockout plan under `World/Stadium/`. The level must feel like an event collapsing under crowd pressure, not just a flat arena.

Include new enemies:
- `Turnstile Shover`: close-range blocker who pushes the player sideways along one depth band.
- `Bottle Thrower`: ranged enemy who throws arcing bottles with clear landing marks and depth-safe collision.
- `Flag Runner`: fast flanker who changes depth before attacking, forcing lane awareness without teleporting.
- Boss `Чемпион`: heavy pressure fighter who uses crowd shockwaves and close boxing patterns.

Include background generation requirements:
- Create an art request for a layered stadium background in `assets/requests/stadium_background.md`.
- Generated candidates must land in `assets/incoming/stadium/`.
- Background must show concrete stands, failing floodlights, turnstiles, fog, torn banners, and a partly collapsing sector without hiding feet or hitboxes.

## Output
Design artifact with gameplay purpose, space/positioning behavior, constraints, acceptance criteria, changed paths, behavior impact, and verification notes. If code is implemented in the same task, include changed Godot paths separately.

## Do Not Change
- `Player/player.gd`
- Shared depth-space combat logic
- One-shot animation loop settings
- Existing factory level scenes

## Acceptance Criteria
- Stadium route has at least 6 named internal zones: gate, turnstiles, lower corridor, stands, field edge, center event area.
- Each zone defines a combat purpose, depth behavior, hazards, enemy composition, and route turn.
- Crowd pressure never closes all depth bands at once.
- New enemy roles define combat role, preferred spacing, attack range, movement pressure, and counterplay.
- Boss `Чемпион` is beatable through spacing and timing, not unavoidable arena-wide hits.
- Background generation request includes size, palette direction, layer plan, expected output paths, and readability constraints.
- No changes are made to `Player/player.gd`.

## Completion Note
Changed paths:
- `docs/level2_stadium_design.md`
- `assets/requests/stadium_background.md`
- `tasks/review/level2_stadium_design_and_blockout.md`

Behavior impact:
- Added a stadium level design/blockout artifact with six named internal zones, route turns, hazards, enemy compositions, and boss phases.
- Added/linked the stadium background request created by the background pipeline task.
- Kept the output as design/art planning only; no Godot scenes or code were changed because the worktree already contains unrelated scene/enemy changes.

Verification notes:
- Read this single task from `tasks/ready/` before implementation.
- Read `docs/global_enemy_roster.md` and scenario stadium references.
- Verified the design states that crowd pressure and boss attacks must preserve depth-aware overlap and safe bands.
