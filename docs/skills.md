# Skills

Skills are grouped by theme:
- `alcohol`: inebriation-cost skills, bottle throws, vomit/fire interactions.
- `smoke`: nicotine-cost skills, smoke ring, dash, crowd control.
- `combo`: skills that depend on combat rhythm or chained actions.
- `package`: item, pickup, or loadout-driven skills.

Skill rules:
- Respect cooldowns.
- Respect resource costs.
- Emit existing skill events consistently.
- Keep projectile spawn timing synchronized with cast or throw animation.
- Projectiles and hit logic must filter targets by actual spatial/depth validity.

Use `skills/Skill.gd` as the base contract and follow existing implementation patterns before adding helpers.
