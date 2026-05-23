# Second Pass Aftermath Levels Design

## Type
Design artifact

## Context
After the five catastrophe visits, `LAST_TOAST_scenario_v2.md` calls for shorter return missions: factory helmet, stadium uniform, bridge light, metro token, forest guitar. These must feel quieter and more emotional than first-pass levels.

## References
- `LAST_TOAST_scenario_v2.md`
- `docs/scenario_russia_90s_adaptation.md`
- `docs/gameplay_core.md`
- `docs/combat.md`
- `docs/enemies.md`
- `docs/art_style_guide.md`

## Task
Create a design artifact for all second-pass aftermath levels. Each return mission should be short, specific, and built around a simple object recovery or repair action with reduced combat pressure.

Include aftermath bosses/enemies:
- Factory: `Хозяин конвейера`, assembled from foam, glass, yeast, and factory leftovers.
- Stadium: `Комментатор`, attacks through pressure, memory, and old crowd noise.
- Bridge: `Паводок`, a moving mass of water, metal, headlights, and river debris.
- Metro: `Сеть`, station systems still working without people.
- Forest: `Следопыт`, a figure with thermal camera and radio who keeps searching for a source outside himself.

Include background variants:
- Define second-pass background generation prompts for all five locations.
- Candidate paths must be `assets/incoming/<location>_aftermath/`.
- Variants must reduce crowd/noise/action and emphasize remaining traces: dried foam, empty stands, river fog, silent tunnel, wet ash.

## Output
Design artifact with gameplay purpose, space/positioning behavior, constraints, acceptance criteria, and verification notes.

## Do Not Change
- `Player/player.gd`
- Shared depth-space combat logic
- One-shot animation loop settings
- First-pass level scenes unless the task explicitly scopes a shared reusable prop

## Acceptance Criteria
- Defines five short aftermath missions with objective, route, object, bar reward, and emotional beat.
- Each mission has fewer enemies than first pass and more environmental reading.
- Each aftermath boss/enemy defines combat role, spacing, attack range, movement pressure, and counterplay.
- Each mission preserves depth-aware targeting and readable safe bands.
- Background variant prompts include size, palette direction, layer plan, expected output paths, and readability constraints.
- Does not turn returns into full repeated levels with only new textures.

## Completion Note
Changed paths:
- `docs/second_pass_aftermath_levels.md`
- `assets/requests/factory_aftermath_background.md`
- `assets/requests/stadium_aftermath_background.md`
- `assets/requests/bridge_aftermath_background.md`
- `assets/requests/metro_aftermath_background.md`
- `assets/requests/forest_aftermath_background.md`
- `tasks/review/second_pass_aftermath_levels_design.md`

Behavior impact:
- Added a design artifact for all five second-pass aftermath missions.
- Defined objective, route, object, bar reward, emotional beat, boss/enemy behavior, counterplay, and background request linkage for each return.
- Kept returns short and quieter than first-pass levels.
- Did not change code, scenes, or player logic.

Verification notes:
- Read this single task from `tasks/ready/` before implementation.
- Read scenario aftermath/object references and used `docs/global_enemy_roster.md` boss-role direction.
- Verified all background variants point to `assets/incoming/<location>_aftermath/` and all missions preserve depth-readable safe bands.
