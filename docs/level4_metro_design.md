# Level 4 Metro Design And Blockout

## Type
Design artifact for a later Godot blockout under `World/Metro/`.

## Gameplay Purpose
The metro level is about rhythm that keeps running after people stop paying attention. The player crosses turnstiles, platform, train, and service strips to stop an uncontrolled train and face `Дежурный`.

## Space And Positioning Model
The route stays one continuous shared combat field. The platform edge is a strong visual boundary and stagger risk, not instant death. Train, doors, wind, sparks, and announcements mark lanes before hazards activate.

## Route Zones

### 1. Entrance
- Purpose: set the empty but operating mood.
- Depth behavior: near lane is stairs/entry, center is open hall, far lane holds booths.
- Hazards: flickering sign only, no damage.
- Enemies: 1 Token Clerk.
- Route turn: player moves from open hall to constrained turnstiles.
- Acceptance: token projectile lane is readable.

### 2. Turnstiles
- Purpose: compress space and introduce station control.
- Depth behavior: turnstiles divide lanes visually; no prop hides feet.
- Hazards: locked gate arms swing after a warning beep.
- Enemies: 1 Token Clerk, 1 Signal Worker.
- Route turn: Signal Worker opens a side service gate after interruption.
- Acceptance: gate hazard never traps all lanes.

### 3. Platform
- Purpose: reveal train danger.
- Depth behavior: near lane is wall side, center is safe platform, far lane is edge.
- Hazards: wind pulse before train pass; far lane stagger if standing at edge.
- Enemies: 1 Tunnel Dragger enters from tunnel shadow.
- Route turn: player is forced from far edge toward center before the first train pass.
- Acceptance: platform edge is readable and recoverable.

### 4. First Train Pass
- Purpose: timed hazard and lane reading.
- Depth behavior: train pass threatens far lane first, then center with wind, near remains safe.
- Hazards: light sweep, wind, sparks in clear order.
- Enemies: 1 Signal Worker controlling timing, optional Token Clerk after pass.
- Route turn: train opens access to a car door.
- Acceptance: train event uses telegraph, safe timing window, and no instant death.

### 5. Car Interior
- Purpose: narrow but still depth-aware fight.
- Depth behavior: seats and poles are background blockers; floor lanes remain visible.
- Hazards: doors slam on marked side zones.
- Enemies: 1 Tunnel Dragger, 1 Token Clerk.
- Route turn: broken door forces exit onto service strip.
- Acceptance: narrow car does not remove depth movement.

### 6. Tunnel Service Strip
- Purpose: controlled darkness and system pressure.
- Depth behavior: near lane is cable walkway, center is service path, far is tunnel shadow.
- Hazards: sparks from cable boxes after Signal Worker warning.
- Enemies: 1 Signal Worker, 1 Tunnel Dragger.
- Route turn: player follows service lamps to braking finale.
- Acceptance: darkness shows silhouettes before active attacks.

### 7. Braking Finale
- Purpose: boss arena for `Дежурный`.
- Depth behavior: wide platform end with console in center and tunnel pressure on far lane.
- Hazards: train rhythm, door slams, announcements, wind pulses.
- Enemies: boss only in phase 1; one Signal Worker echo may appear in phase 2.
- Route turn: emergency stop opens return path.
- Acceptance: station systems act in marked depth bands with safe windows.

## Enemy Use
- Token Clerk marks and controls lanes with token projectiles.
- Tunnel Dragger emerges slowly from darkness and commits to a lane.
- Signal Worker changes light and hazard timing but can be interrupted.
- `Дежурный` coordinates train rhythm, announcements, doors, and platform timing.

## Boss: Дежурный
- Phase 1: baton/lantern attacks in same lane, short token throws.
- Phase 2: announcement warnings precede doors, wind, and sparks on individual bands.
- Phase 3: train stop sequence; player must trigger console windows while avoiding marked lanes.
- Counterplay: listen/read warning boards, leave marked lanes, interrupt station controls.
- Constraint: boss systems must not overlap to remove all safe bands.

## Background Request
Use `assets/requests/metro_background.md`. Candidates must go to `assets/incoming/metro/`. Faded ads, route board, tunnel mouth, and train silhouettes must stay behind clear combat lanes.

## Constraints
- Do not make the metro a horror tunnel.
- Do not use platform fall as a death pit.
- Do not hide active hitboxes in darkness or train blur.
- Do not modify `Player/player.gd`.

## Acceptance Criteria
- Seven named zones are defined with purpose, depth behavior, hazards, enemies, and route turns.
- New metro enemy roles map to `docs/global_enemy_roster.md`.
- `Дежурный` uses station systems in depth-aware patterns.
- Background request exists and points to `assets/incoming/metro/`.
- This artifact can guide a minimal `World/Metro/` blockout without changing shared combat logic.
