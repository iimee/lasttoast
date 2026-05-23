extends Node
const ItemID = preload("res://db/ItemDB.gd")

@export var bottle_charges := 2
@export var pack_charges := 5
@export var cig_inebriation_gain := 1

func use_full_bottle() -> bool:
	if not Inventory.take(ItemID.FULL_BOTTLE, 1):
		return false
	Resources.add_inebriation(bottle_charges)
	Inventory.add(ItemID.EMPTY_BOTTLE, 1)
	return true

func use_cig_pack() -> bool:
	if not Inventory.take(ItemID.CIG_PACK, 1):
		return false
	Resources.add_nicotine(pack_charges)
	Resources.add_inebriation(cig_inebriation_gain)
	return true
