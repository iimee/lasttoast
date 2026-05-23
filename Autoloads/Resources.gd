extends Node
signal inebriation_changed(v: int)
signal nicotine_changed(v: int)

@export var max_inebriation := 12
@export var max_nicotine := 30

var inebriation := 9
var nicotine := 9

func add_inebriation(n: int) -> void:
	inebriation = clamp(inebriation + n, 0, max_inebriation)
	emit_signal("inebriation_changed", inebriation)

func add_nicotine(n: int) -> void:
	nicotine = clamp(nicotine + n, 0, max_nicotine)
	emit_signal("nicotine_changed", nicotine)
