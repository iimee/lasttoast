# Background Generation Pipeline

## Type
Art and tooling artifact

## Context
The scenario needs generated backgrounds for multiple levels, but the project asset pipeline requires generated candidates to land in `assets/incoming/` first and final assets to move only after review.

## References
- `LAST_TOAST_scenario_v2.md`
- `docs/art_style_guide.md`
- `docs/asset_pipeline.md`
- `docs/scenario_russia_90s_adaptation.md`

## Task
Create a repeatable background generation workflow for the project. The workflow should produce request files and clear prompts for:
- Stadium first pass.
- Bridge first pass.
- Metro first pass.
- Forest camp first pass.
- Five aftermath variants.
- Toilet mirror.
- Final bar.

The workflow may include a script or template, but must not overwrite final assets automatically.

## Output
Art/tooling artifact with changed paths, behavior impact, verification notes, and generated request paths.

## Do Not Change
- `Player/player.gd`
- Shared combat logic
- Existing final assets
- Existing imported assets unless explicitly scoped

## Acceptance Criteria
- Adds a reusable request template under `assets/requests/` or `docs/`.
- Adds concrete background request files for each required location.
- Each request defines target size, aspect, pixel-art style direction, palette, parallax/layer needs, foreground readability constraints, expected incoming path, and review criteria.
- Generated candidates, if any are produced, land only under `assets/incoming/`.
- No files are moved to `assets/final/`.
- Prompts avoid parody, excessive gore, unreadable clutter, and over-detailed pixel noise.

## Completion Note
Changed paths:
- `assets/requests/background_request_template.md`
- `assets/requests/stadium_background.md`
- `assets/requests/bridge_background.md`
- `assets/requests/metro_background.md`
- `assets/requests/forest_camp_background.md`
- `assets/requests/factory_aftermath_background.md`
- `assets/requests/stadium_aftermath_background.md`
- `assets/requests/bridge_aftermath_background.md`
- `assets/requests/metro_aftermath_background.md`
- `assets/requests/forest_aftermath_background.md`
- `assets/requests/toilet_mirror_background.md`
- `assets/requests/final_bar_background.md`
- `tasks/review/background_generation_pipeline.md`

Behavior impact:
- Added a reusable background request template.
- Added concrete first-pass, aftermath, mirror, and final bar background request files.
- Each request defines target size, aspect, style, palette, layers, readability constraints, expected incoming/final paths, prompt, negative prompt, and review criteria.
- Did not generate or move any final production assets.

Verification notes:
- Read this single task from `tasks/ready/` before implementation.
- Read `docs/art_style_guide.md`, `docs/asset_pipeline.md`, and scenario headings for the relevant level beats.
- Confirmed all background requests point candidates to `assets/incoming/` and keep `assets/final/` review-only.
