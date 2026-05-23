# Gameplay Core

The game uses one shared combat field with pseudo-depth. Actors may move along X and depth Y, and combat must stay readable and spatially consistent across that shared space.

The player is a `CharacterBody2D`. Locomotion must always recover after one-shot actions such as hit, dash, throw, cast, or knockback.

`AnimatedSprite2D` controls one-shot animations. One-shot animations must end through a signal, timer, or watchdog fallback and return to idle/run unless a valid state lock remains active.

Depth lock logic protects positional consistency during actions. Preserve it when changing movement, dash, hit reactions, throws, or skill casts.
