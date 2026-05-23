extends "res://Combat/Projectiles/BottleFly.gd"

@export var collision_layer_override: int = Layers.E_ATTACK
@export var collision_mask_override: int = Layers.PLAYER | Layers.WORLD | Layers.TRIGGER | Layers.HAZARD

func _ready() -> void:
	super._ready()
	collision_layer = collision_layer_override
	collision_mask = collision_mask_override
