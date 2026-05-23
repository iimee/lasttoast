# Combat

Combat must be readable, depth-aware, and recoverable.

Rules:
- Attacks, hitboxes, and projectiles must respect actual spatial overlap on the shared field.
- Hitstop may pause feel briefly but must not leave movement, animations, or skills stuck.
- Knockback must preserve valid depth/position state.
- Invulnerability windows must have a clear start and end.
- Damage should apply once per intended hit event.
- Any state lock needs one source of truth, an exit condition, and a watchdog fallback.

Close-range skills must remain responsive. Timing changes should not delay damage so far that nearby targets become impossible to hit.
