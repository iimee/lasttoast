extends Node

signal inventory_changed(id: String, count: int)

const ItemDB = preload("res://db/ItemDB.gd")

var _count: Dictionary = {
	ItemDB.FULL_BOTTLE: 10,
	ItemDB.EMPTY_BOTTLE: 10,
	ItemDB.CIG_PACK: 10,
}

func get_count(id: String) -> int:
	return int(_count.get(id, 0))

func set_count(id: String, n: int) -> void:
	_count[id] = max(0, n)
	emit_signal("inventory_changed", id, _count[id])

func add(id: String, n: int = 1) -> void:
	set_count(id, get_count(id) + n)

func take(id: String, n: int = 1) -> bool:
	if get_count(id) < n:
		return false
	set_count(id, get_count(id) - n)
	return true

# Удобные шорткаты
func add_full_bottle(n: int = 1) -> void: add(ItemDB.FULL_BOTTLE, n)
func add_empty_bottle(n: int = 1) -> void: add(ItemDB.EMPTY_BOTTLE, n)
func add_cigs(n: int = 1) -> void: add(ItemDB.CIG_PACK, n)
