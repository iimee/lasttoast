# Level 3 Bridge Design And Blockout

## Type
Design artifact for a later Godot blockout under `World/Bridge/`.

## Gameplay Purpose
The bridge level is about responsibility hidden in paperwork, shortcuts, and delayed maintenance. The player must cross an unstable wet bridge, stop the runaway truck, and face `Инженер` without letting collapse hazards overwhelm the shared combat field.

## Space And Positioning Model
The bridge is a long continuous deck with near shoulder, center truck lane, and far railing/service lane. Collapse, headlights, and cables are lane events. They must telegraph first and never act as instant death.

## Route Zones

### 1. Approach Road
- Safe bands: near and center open; far lane has parked debris.
- Hazard timing: wind gust pushes loose signs after a visible sway.
- Enemy pressure: 1 Raincoat Guard.
- Route turn: player is guided from open road toward the narrow bridge entrance.
- Acceptance: bridge instability is introduced without damage spikes.

### 2. First Railing
- Safe bands: center is safest; near railing briefly sparks; far lane narrows.
- Hazard timing: railing cable snaps after two-frame light flash and sound cue.
- Enemy pressure: 1 Cable Hook, 1 Raincoat Guard.
- Route turn: snapped railing blocks near lane, forcing a center/far shift.
- Acceptance: Cable Hook never pulls across hidden depth mismatch.

### 3. Truck Lane
- Safe bands: near and far lanes alternate safety as headlights sweep center.
- Hazard timing: truck headlights mark the lane before a straight pass.
- Enemy pressure: 1 Headlight Sprinter, later 1 Cable Hook.
- Route turn: player crosses through center only during headlight recovery windows.
- Acceptance: truck/headlight pressure is readable and not instant death.

### 4. Service Shoulder
- Safe bands: far service strip is open; center has puddles; near lane has rail gaps.
- Hazard timing: rain puddles spark after cable warning.
- Enemy pressure: 2 Raincoat Guards in staggered positions.
- Route turn: player uses the far strip to bypass a blocked truck lane.
- Acceptance: shields narrow space but leave one lane escape.

### 5. Cracked Span
- Safe bands: safe lane rotates every beat: near, center, far.
- Hazard timing: cracks pulse and shed dust before a panel drops.
- Enemy pressure: 1 Cable Hook, 1 Headlight Sprinter.
- Route turn: a dropped panel opens the route downward/forward, changing the fighting line.
- Acceptance: collapse panels are warning zones, not surprise holes.

### 6. Central Break
- Safe bands: center is boss lane, near has puddle pressure, far has cable console.
- Hazard timing: cables whip after visible tension lines.
- Enemy pressure: boss `Инженер`; no regular adds in first phase.
- Route turn: after victory, emergency light route opens back to the bar.
- Acceptance: boss tests cable/panel positioning and preserves shared-field overlap.

## Enemy Use
- Cable Hook punishes stillness at mid-range and teaches lane-line warnings.
- Raincoat Guard anchors railings and creates temporary side pressure.
- Headlight Sprinter uses reflection/headlight telegraphs before linear rushes.
- `Инженер` uses cable zones, unstable panels, and precise attacks tied to diagrams.

## Boss: Инженер
- Phase 1: same-lane folder/pipe strikes and cable line previews.
- Phase 2: marks cracked panels from his diagram; one lane becomes unsafe after a delay.
- Phase 3: tries to hold the bridge together by activating emergency cables; the player must move through safe bands and interrupt console actions.
- Counterplay: read diagram marks, leave cable lanes, punish long recovery after failed cable pulls.
- Constraint: no cable, panel, or truck echo may hit unless the player is actually in the marked band.

## Background Request
Use `assets/requests/bridge_background.md`. Candidates must go to `assets/incoming/bridge/`. Rain and river darkness must stay behind readable lane and foot silhouettes.

## Constraints
- Do not use falling as the main difficulty.
- Do not let rain, reflections, cables, or railings hide feet.
- Do not close all lanes with truck, cable, and collapse at once.
- Do not modify `Player/player.gd`.

## Acceptance Criteria
- Six named zones are defined with safe bands, hazard timing, enemy pressure, and route turns.
- New bridge enemy roles map to `docs/global_enemy_roster.md`.
- `Инженер` has depth-aware phases and counterplay.
- Background request exists and points to `assets/incoming/bridge/`.
- This artifact can guide a minimal `World/Bridge/` blockout without changing shared combat logic.
