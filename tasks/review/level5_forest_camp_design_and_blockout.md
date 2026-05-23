# Level 5 Forest Camp Design And Blockout

## Type
Design artifact, then code artifact

## Context
Build the fifth main level from `LAST_TOAST_scenario_v2.md`: заброшенный лагерь у леса, пожар, деревянные корпуса, столовая, спортплощадка, дым, дождь, пепел and the boss `Лесник / Сторож`.

## References
- `LAST_TOAST_scenario_v2.md`
- `docs/scenario_russia_90s_adaptation.md`
- `docs/gameplay_core.md`
- `docs/combat.md`
- `docs/enemies.md`
- `docs/art_style_guide.md`
- `docs/asset_pipeline.md`

## Task
Create an executable task output for the forest camp level: route design and minimal playable blockout plan under `World/ForestCamp/`. The level must be about stopping fire from spreading, not about spectacle or horror.

Include new enemies:
- `Ash Runner`: evasive enemy who uses smoke cover but must reappear before attacking.
- `Ember Carrier`: hazard enemy who drops small fire patches with visible startup and limited lifetime.
- `Wet Plank Brute`: slow heavy enemy who controls narrow wooden passages and can be baited into breaking weak boards.
- Boss `Лесник`: uses fire lines, water pump beats, and guarded movement through smoke.

Include background generation requirements:
- Create an art request for a layered forest camp background in `assets/requests/forest_camp_background.md`.
- Generated candidates must land in `assets/incoming/forest_camp/`.
- Background must show wet ash, burnt trees, wooden dorms, dining hall signs, sports ground remnants, smoke layers, rain, and a water tower silhouette.

## Output
Design artifact with gameplay purpose, space/positioning behavior, constraints, acceptance criteria, changed paths, behavior impact, and verification notes. If code is implemented in the same task, include changed Godot paths separately.

## Do Not Change
- `Player/player.gd`
- Shared depth-space combat logic
- One-shot animation loop settings
- Existing factory level scenes

## Acceptance Criteria
- Forest camp route has at least 7 named internal zones: road edge, first cabins, dining hall, sports ground, pump shed, roof/beam hazard, fireline finale.
- Fire and smoke never hide active hitboxes, actor feet, or all safe depth bands.
- Water pump and extinguishing interactions use short recoverable actions.
- New enemy roles define combat role, preferred spacing, attack range, movement pressure, and counterplay.
- Boss `Лесник` checks controlled movement and fire management, not raw unavoidable damage.
- Background generation request includes size, palette direction, layer plan, expected output paths, and readability constraints.
- No changes are made to `Player/player.gd`.

## Completion Note
Changed paths:
- `docs/level5_forest_camp_design.md`
- `assets/requests/forest_camp_background.md`
- `tasks/review/level5_forest_camp_design_and_blockout.md`

Behavior impact:
- Added a forest camp level design/blockout artifact with seven named route zones, fire/smoke rules, water pump interactions, enemy compositions, and boss phases.
- Added/linked the forest camp background request created by the background pipeline task.
- Kept the output as design/art planning only; no Godot scenes or code were changed because the worktree already contains unrelated scene/enemy changes.

Verification notes:
- Read this single task from `tasks/ready/` before implementation.
- Read scenario forest camp references and used `docs/global_enemy_roster.md` roles.
- Verified the design requires fire, smoke, pump interactions, and boss attacks to preserve actor feet, hitbox readability, and safe depth bands.
