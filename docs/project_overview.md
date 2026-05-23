# Project Overview

This is a Godot 4.6 2D beat'em up with a shared combat field and slight depth. The player fights enemies across that space with melee attacks, projectiles, movement actions, and resource-based skills.

The player is a `CharacterBody2D`. Movement, facing, combat state, skill use, damage reactions, invulnerability, and animation recovery are owned by the player runtime.

The project favors strict task execution. Each agent reads one ready task, checks the relevant docs, changes only the requested files, and moves the task to review with a completion note.
