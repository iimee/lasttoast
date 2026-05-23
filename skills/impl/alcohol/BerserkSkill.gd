extends Skill
class_name Berserk

const ItemDB = preload("res://db/ItemDB.gd")

@export var duration: float = 10.0
@export var prefer_empty_bottle: bool = true
@export var hp_cost: int = 0
@export var nicotine_cost: int = 2

func can_use(user: Node) -> bool:
	if user == null:
		return false
	var tree: SceneTree = user.get_tree()
	if tree == null:
		return false
	var inv: Node = tree.root.get_node_or_null("Inventory")
	if inv == null:
		return false
	var empty_cnt: int = int(inv.call("get_count", ItemDB.EMPTY_BOTTLE))
	var full_cnt: int = int(inv.call("get_count", ItemDB.FULL_BOTTLE))
	if (empty_cnt + full_cnt) <= 0:
		return false
	if not _can_pay_hp(user, hp_cost):
		return false
	if nicotine_cost <= 0:
		return true
	var res: Node = tree.root.get_node_or_null("Resources")
	if res == null:
		return false
	var nic: int = int(res.get("nicotine"))
	return nic >= nicotine_cost

func execute(user: Node) -> void:
	if user == null:
		return
	var tree: SceneTree = user.get_tree()
	if tree == null:
		return
	var inv: Node = tree.root.get_node_or_null("Inventory")
	var res: Node = tree.root.get_node_or_null("Resources")
	if inv == null or res == null:
		return

	var empty_cnt: int = int(inv.call("get_count", ItemDB.EMPTY_BOTTLE))
	var full_cnt: int = int(inv.call("get_count", ItemDB.FULL_BOTTLE))
	var spend_id: String = ""
	if prefer_empty_bottle:
		if empty_cnt > 0:
			spend_id = ItemDB.EMPTY_BOTTLE
		elif full_cnt > 0:
			spend_id = ItemDB.FULL_BOTTLE
	else:
		if full_cnt > 0:
			spend_id = ItemDB.FULL_BOTTLE
		elif empty_cnt > 0:
			spend_id = ItemDB.EMPTY_BOTTLE
	if spend_id == "":
		return

	if nicotine_cost > 0:
		var nic: int = int(res.get("nicotine"))
		if nic < nicotine_cost:
			return
	if hp_cost > 0 and not _can_pay_hp(user, hp_cost):
		return
	if not bool(inv.call("take", spend_id, 1)):
		return
	if hp_cost > 0 and not _spend_hp(user, hp_cost):
		return
	if nicotine_cost > 0:
		res.call("add_nicotine", -nicotine_cost)
	if user.has_method("berserk_start"):
		user.berserk_start(duration)

func _can_pay_hp(user: Node, cost: int) -> bool:
	if cost <= 0:
		return true
	if user.has_method("can_pay_hp_cost"):
		return bool(user.call("can_pay_hp_cost", cost))
	if user is Object:
		var hp: int = int((user as Object).get("hp"))
		return hp > cost
	return false

func _spend_hp(user: Node, cost: int) -> bool:
	if cost <= 0:
		return true
	if user.has_method("spend_skill_hp"):
		return bool(user.call("spend_skill_hp", cost))
	return false
