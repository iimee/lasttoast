# Mirror And Last Toast Final Levels Design

## Type
Design artifact

## Context
`LAST_TOAST_scenario_v2.md` ends with the bar toilet mirror fight and the final bar confrontation. These are levels, but they should test control, patience, and memory more than raw damage.

## References
- `LAST_TOAST_scenario_v2.md`
- `docs/scenario_russia_90s_adaptation.md`
- `docs/gameplay_core.md`
- `docs/combat.md`
- `docs/enemies.md`
- `docs/art_style_guide.md`

## Task
Create a design artifact for:
- Toilet / mirror level with boss `Отражение`.
- Final bar level with bartender confrontation, aftermath echoes, NPC support beats, and final pour minigame.

Include new enemy/boss behavior:
- `Отражение`: copies old player habits, punishes spam, overuses alcohol/cigarette skills, and forces cleaner timing.
- `Debt Echo`: temporary non-boss echo from previous locations, always tied to a readable lane or environmental cue.
- `Bartender`: first fights simply, then coordinates bar systems and memory echoes, then steps aside for the reflection phase.

Include background generation requirements:
- Create art requests for `assets/requests/toilet_mirror_background.md` and `assets/requests/final_bar_background.md`.
- Generated candidates must land in `assets/incoming/toilet_mirror/` and `assets/incoming/final_bar/`.
- Backgrounds must keep the playable floor and actor feet readable despite mirror cracks, tiles, smoke, steam, light failures, and bar clutter.

## Output
Design artifact with gameplay purpose, space/positioning behavior, constraints, acceptance criteria, changed paths if any, and verification notes.

## Do Not Change
- `Player/player.gd`
- Shared depth-space combat logic
- One-shot animation loop settings
- Existing level scenes unless explicitly needed for references

## Acceptance Criteria
- Mirror fight defines how `Отражение` observes or approximates player habits without requiring invasive changes to `Player/player.gd`.
- Final fight has clear phases: bar fight, consequences enter, NPCs stabilize hazards, reflection returns, final pour.
- Previous-location echoes are hazards/enemy beats, not a crowded boss army.
- Final pour is a control test and cannot be solved by attacking.
- Background generation requests include size, palette direction, layer plan, expected output paths, and readability constraints.
- The ending keeps the tone grounded: no demon reveal, no moral speech, no spectacle for its own sake.

## Completion Note
Changed paths:
- `docs/mirror_toast_final_levels.md`
- `assets/requests/toilet_mirror_background.md`
- `assets/requests/final_bar_background.md`
- `tasks/review/mirror_toast_final_levels_design.md`

Behavior impact:
- Added a design artifact for the toilet mirror fight and final bar level.
- Defined non-invasive habit approximation for `Отражение`, final bar phases, Debt Echo behavior, NPC stabilization beats, and final pour rules.
- Added/linked the toilet mirror and final bar background requests created by the background pipeline task.
- Did not change code, scenes, or player logic.

Verification notes:
- Read this single task from `tasks/ready/` before implementation.
- Read scenario mirror/final references and used `docs/global_enemy_roster.md` finale-role direction.
- Verified the final pour is specified as a control test, not an attack/damage solution, and that the ending avoids demon reveal or spectacle escalation.
