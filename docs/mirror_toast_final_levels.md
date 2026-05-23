# Mirror And Last Toast Final Levels Design

## Type
Design artifact for the toilet mirror level and final bar level.

## Shared Purpose
These final levels test control, patience, and recognition. They should not become demon reveals, moral speeches, or spectacle fights. The player wins by reading habits, stabilizing consequences, and finally pouring evenly.

## Toilet / Mirror Level

### Gameplay Purpose
The toilet is a small space where the player meets a frozen old version of himself. The fight is about recognizing and correcting habits, not destroying a monster.

### Space And Positioning Behavior
- Compact arena with three narrow but valid depth bands.
- Mirror stays on the back wall above active combat space.
- Sink and pipe props sit outside the foot line.
- Flickering lamp can mark timing, but never hides hitboxes.

### Boss: Отражение
- Role: habit mirror and spam punisher.
- Habit approximation without `Player/player.gd` changes: use encounter-local counters for recent player actions observed through existing combat events, such as repeated attack input windows, frequent projectile/skill use, or repeated same-lane approaches.
- Behavior: if the player repeats one pattern three times in a short window, `Отражение` prepares the exaggerated version of that habit.
- Alcohol/cigarette overuse: boss can use unsafe versions of similar skill archetypes, but with longer startup and clear recovery.
- Attack range: same-lane melee, short dash, delayed projectile, and punish zone after repeated spam.
- Movement pressure: forces the player to vary depth, pause, and punish recovery.
- Counterplay: change rhythm, wait out overcommitted attacks, step out of marked lanes.
- Constraint: no invasive player script instrumentation is required for the design pass.

### Mirror Fight Phases
- Phase 1: copy old close attacks and same-lane pressure.
- Phase 2: punish repeated patterns with exaggerated unsafe skill echoes.
- Phase 3: mirror lag becomes visible; boss attacks slower, leaving clean recovery windows.
- End beat: mirror does not explode; it stops distorting.

### Background Request
Use `assets/requests/toilet_mirror_background.md`. Candidates must go to `assets/incoming/toilet_mirror/`.

## Final Bar Level

### Gameplay Purpose
The final bar fight gathers consequences into one room, then turns away from violence. The ending challenge is the final pour: control, not damage.

### Space And Positioning Behavior
- Bar floor is a wide shared combat field with near open floor, center bar lane, and far doors/windows.
- Bar clutter remains behind the active plane.
- NPC support beats happen at edges and stabilize hazards rather than attacking the boss.

### Phase 1: Bar Fight
- Bartender fights simply: bottle tosses, short grabs, counter shoves.
- Attacks are readable and same-lane.
- Goal: establish that this is a human fight, not a supernatural one.

### Phase 2: Consequences Enter
- Debt Echoes appear as temporary hazards tied to previous locations:
  - Factory steam lane.
  - Stadium floodlight/crowd pulse.
  - Bridge rain/cable lane.
  - Metro door/wind pulse.
  - Forest ember/smoke lane.
- Echoes do one marked action and dissolve.
- No crowded boss army.

### Phase 3: People Hold The Room
- Foreman shuts off steam.
- Champion holds falling shelf/stand prop.
- Engineer restores light.
- Duty Officer opens a passage/timing window.
- Forester extinguishes a small flame.
- NPCs do not deal boss damage; they make the room playable again.

### Phase 4: Reflection Returns
- Bartender steps aside.
- `Отражение` returns briefly, using the cleanest version of the mirror fight rules.
- Purpose: show that the real check is the player's own rhythm.

### Phase 5: Last Toast
- Combat ends.
- A glass appears on the counter.
- Player must pour evenly using controlled input/timing.
- Fail states: rushing tips the glass; overpour shakes the bar; attacking does nothing and delays reset.
- Success: steady pour, silence, bartender line, transition to epilogue.

## Final Boss Behavior

### Bartender
- Role: simple human opponent and room coordinator.
- Spacing: center/near lanes around counter.
- Attack range: short melee, medium bottle toss.
- Movement pressure: pushes player toward bar systems but leaves escape bands.
- Counterplay: dodge same-lane attacks, close during bottle recovery, avoid Debt Echo lanes.

### Debt Echo
- Role: temporary memory hazard.
- Spacing: one clearly marked lane tied to location cue.
- Attack range: one sweep/pulse.
- Movement pressure: forces recognition without adding enemy clutter.
- Counterplay: leave the marked lane and resume.

## Background Request
Use `assets/requests/final_bar_background.md`. Candidates must go to `assets/incoming/final_bar/`.

## Constraints
- Do not make the ending a demon reveal.
- Do not solve the final pour with attacks or damage.
- Do not use previous-location echoes as a swarm.
- Do not require modifications to `Player/player.gd`.
- Do not hide feet with bar props, steam, smoke, or light failures.

## Acceptance Criteria
- Mirror fight defines non-invasive habit approximation.
- Final fight has phases for bar fight, consequences, NPC stabilization, reflection return, and final pour.
- Debt Echoes are temporary marked hazards, not a boss army.
- Final pour is a control test and cannot be solved by attacking.
- Background requests exist for toilet mirror and final bar.
- The ending remains grounded, quiet, and readable.
