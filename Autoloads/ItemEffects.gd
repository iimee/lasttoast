extends Node
const ItemID = preload("res://db/ItemDB.gd")

@export var bottle_charges := 3   # сколько «стаканов» даёт одна полная бутылка
@export var pack_charges := 5     # сколько «затяжек»/очков даёт пачка

func use_full_bottle() -> bool:
	if not Inventory.take(ItemID.FULL_BOTTLE, 1):
		return false
	Resources.add_inebriation(bottle_charges)
	Inventory.add(ItemID.EMPTY_BOTTLE, 1)  # выпил -> пустая на валюту/боеприпасы
	return true

func use_cig_pack() -> bool:
	if not Inventory.take(ItemID.CIG_PACK, 1):
		return false
	Resources.add_nicotine(pack_charges)
	return true
