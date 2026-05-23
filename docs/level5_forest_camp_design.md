# Level 5 Forest Camp Design And Blockout

## Type
Design artifact for a later Godot blockout under `World/ForestCamp/`.

## Gameplay Purpose
The forest camp level is about stopping fire from spreading and facing the cost of leaving something small unfinished. It should feel like a fight through consequences, not a horror setpiece.

## Space And Positioning Model
The route uses one continuous shared combat field through camp paths, buildings, and firelines. Smoke softens the background but never hides feet, hitboxes, or active telegraphs. Fire denies small marked patches with limited lifetime.

## Route Zones

### 1. Road Edge
- Purpose: introduce rain, ash, and distant fire.
- Depth behavior: near lane is wet road, center is camp path, far is tree line.
- Hazards: falling ash only; no damage yet.
- Enemies: 1 Ash Runner.
- Route turn: player leaves road and enters camp through center path.
- Acceptance: smoke cover shows silhouettes before attacks.

### 2. First Cabins
- Purpose: teach small fire patch management.
- Depth behavior: cabins sit behind far lane; near lane remains open.
- Hazards: Ember Carrier drops one marked fire patch at a time.
- Enemies: 1 Ember Carrier, 1 Ash Runner.
- Route turn: collapsed porch blocks forward path, forcing near-lane bypass.
- Acceptance: fire patches do not cover all safe bands.

### 3. Dining Hall
- Purpose: emotional anchor and later guitar location.
- Depth behavior: wide hall front with center doorway and far window line.
- Hazards: smoke gusts reduce far background only.
- Enemies: 1 Wet Plank Brute guarding doorway, 1 Ember Carrier.
- Route turn: brute can be baited into breaking weak boards to open the next path.
- Acceptance: board break is useful but not required for survival.

### 4. Sports Ground
- Purpose: open arena with movement test.
- Depth behavior: near lane has wet court paint, center is open, far lane has old goal frames.
- Hazards: ember line crosses one lane after wind cue.
- Enemies: 2 Ash Runners, staggered.
- Route turn: player follows safe court markings toward pump shed.
- Acceptance: open space lets the player recover from cabin/dining compression.

### 5. Pump Shed
- Purpose: first extinguishing interaction.
- Depth behavior: pump handle on far lane, hose route through center, near lane for retreat.
- Hazards: short flare-ups if pump is ignored too long.
- Enemies: 1 Wet Plank Brute, 1 Ember Carrier after first pump action.
- Route turn: water pressure opens a path through a burning fence.
- Acceptance: pump uses short recoverable actions, not a long helpless lock.

### 6. Roof And Beam Hazard
- Purpose: controlled falling structure without platforming.
- Depth behavior: center lane passes under beams, near/far lanes are alternately safe.
- Hazards: beams creak and cast shadows before falling.
- Enemies: 1 Ash Runner, 1 Wet Plank Brute.
- Route turn: fallen beam closes center and opens far detour.
- Acceptance: falling beams are telegraphed and do not hide active enemies.

### 7. Fireline Finale
- Purpose: boss arena for `Лесник`.
- Depth behavior: fireline in far lane, pump/hose point in center, wet ash near lane.
- Hazards: fire lines advance one band at a time and retreat after water beats.
- Enemies: boss only at start; one Ember Carrier support may appear in phase 2.
- Route turn: final extinguish beat opens return to bar.
- Acceptance: victory comes from controlled movement and fire management.

## Enemy Use
- Ash Runner uses smoke movement but must reveal before attack.
- Ember Carrier drops limited, bordered fire patches.
- Wet Plank Brute controls narrow passages and can break weak boards.
- `Лесник` uses fire lines, pump windows, and guarded smoke movement.

## Boss: Лесник
- Phase 1: close staff/axe-handle attacks and smoke repositioning with reveal trails.
- Phase 2: fireline advances on marked lanes; player must use pump windows.
- Phase 3: rain increases, fire weakens, `Лесник` slows; player completes final extinguish action.
- Counterplay: track smoke trails, keep one lane open, use short pump actions between attacks.
- Constraint: smoke and fire cannot hide active hitboxes or remove all safe bands.

## Background Request
Use `assets/requests/forest_camp_background.md`. Candidates must go to `assets/incoming/forest_camp/`. Smoke layers, rain, and burnt wood must preserve readable floor values.

## Constraints
- Do not make the camp a gore or horror scene.
- Do not let smoke hide active combat.
- Do not make extinguishing interactions long helpless locks.
- Do not modify `Player/player.gd`.

## Acceptance Criteria
- Seven named zones are defined with purpose, depth behavior, hazards, enemies, and route turns.
- New forest camp enemy roles map to `docs/global_enemy_roster.md`.
- `Лесник` tests controlled movement and fire management.
- Background request exists and points to `assets/incoming/forest_camp/`.
- This artifact can guide a minimal `World/ForestCamp/` blockout without changing shared combat logic.
