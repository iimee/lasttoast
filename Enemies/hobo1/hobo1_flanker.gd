extends "res://Enemies/hobo1/hobo1.gd"

@export var flank_back_offset_px: float = 42.0
@export var flank_run_speed: float = 98.0

func _ready() -> void:
	prefer_player_back = true
	back_offset_px = flank_back_offset_px
	run_speed = maxf(run_speed, flank_run_speed)
	super._ready()
