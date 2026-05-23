# Level 2 Stadium Design And Blockout

## Type
Design artifact for a later Godot blockout under `World/Stadium/`.

## Gameplay Purpose
The stadium is a level about pressure from an event that has already stopped being a game. The player must cross a collapsing public space, reach the center, and face `Чемпион`, whose strength comes from habit and crowd expectation.

## Space And Positioning Model
The route is one continuous side-view combat field with near, center, and far depth bands. Crowd pressure acts as temporary lane pressure, not a solid wall. Hazards must mark the affected lane before activation and leave at least one safe band.

## Route Zones

### 1. Gate
- Purpose: introduce the stadium as tired and unstable.
- Depth behavior: near lane is open pavement, center lane is gate flow, far lane is fence/booth pressure.
- Hazards: crowd shoulder surges across center only.
- Enemies: 1 Turnstile Shover.
- Route turn: player enters through the far gate, then is pushed toward center.
- Acceptance: player reads that crowd pressure is lane-based.

### 2. Turnstiles
- Purpose: teach physical compression without trapping the player.
- Depth behavior: turnstile props divide lanes visually but do not hide feet.
- Hazards: swinging turnstile arms mark one lane at a time.
- Enemies: 2 Turnstile Shovers, later 1 Bottle Thrower.
- Route turn: blocked center path forces a near-lane detour.
- Acceptance: player can escape every shove by changing depth.

### 3. Lower Corridor
- Purpose: shift from public crowd to backstage pressure.
- Depth behavior: lower ceiling, wider near lane, far lane has service doors.
- Hazards: flickering lights reduce background visibility but not active hitboxes.
- Enemies: 1 Bottle Thrower, 1 Flag Runner.
- Route turn: player exits upward to stands after clearing service door pressure.
- Acceptance: ranged bottle marks are visible under light flicker.

### 4. Stands
- Purpose: make the crowd feel like terrain.
- Depth behavior: far lane is stair/stand edge, center is landing, near is open concrete.
- Hazards: crowd wave descends diagonally but affects only one lane per beat.
- Enemies: 1 Turnstile Shover, 1 Flag Runner, optional Bottle Thrower after first pass.
- Route turn: collapsing step blocks forward movement; player drops to field edge.
- Acceptance: stands create route shape without becoming a platforming trap.

### 5. Field Edge
- Purpose: create a rest/read before the boss.
- Depth behavior: wide clean lanes, field paint helps band separation.
- Hazards: sweeping floodlight cone warns incoming rush lanes.
- Enemies: 2 Flag Runners in staggered timing.
- Route turn: player follows a floodlight opening toward center.
- Acceptance: player understands head-on rushes and diagonal flankers before the boss.

### 6. Center Event Area
- Purpose: boss arena for `Чемпион`.
- Depth behavior: widest arena; near lane has mud and bottles, center is fight lane, far lane has ropes/lights.
- Hazards: crowd shockwave is a visible lane ripple, never full-arena.
- Enemies: no standard adds in phase 1; one Bottle Thrower support in phase 2 if readability holds.
- Route turn: victory fades crowd pressure and opens return to bar.
- Acceptance: boss is solved through spacing and timing, not unavoidable hits.

## Enemy Use
- Turnstile Shover anchors lanes and teaches same-depth shove counterplay.
- Bottle Thrower marks landing zones and punishes passive spacing.
- Flag Runner changes depth before committing, forcing lane awareness.
- `Чемпион` uses short boxing strings, shoulder checks, and crowd shockwaves with clear startup.

## Boss: Чемпион
- Phase 1: close boxing, same-lane jabs and hooks with recoverable misses.
- Phase 2: crowd memory pulses mark one lane, then `Чемпион` advances behind them.
- Phase 3: lights fail, his attacks slow but hit harder; he becomes easier to read, not more magical.
- Counterplay: change depth before rushes, punish whiff recovery, avoid marked shockwave lanes.
- Constraint: no attack may hit outside the shown lane or ignore shared-field overlap.

## Background Request
Use `assets/requests/stadium_background.md`. Candidates must go to `assets/incoming/stadium/`. Background must keep the lower combat floor clean and should not add dense crowd silhouettes over active lanes.

## Constraints
- Do not make the stadium a generic arena or sports spectacle.
- Do not close all depth lanes with crowd pressure.
- Do not hide feet with turnstiles, banners, or railings.
- Do not modify `Player/player.gd`.

## Acceptance Criteria
- Six named zones are defined with purpose, depth behavior, hazards, enemies, and route turns.
- New enemies have level-specific usage mapped from `docs/global_enemy_roster.md`.
- `Чемпион` has depth-aware phases and counterplay.
- Background request exists and points to `assets/incoming/stadium/`.
- This artifact can guide a minimal `World/Stadium/` blockout without changing shared combat logic.
