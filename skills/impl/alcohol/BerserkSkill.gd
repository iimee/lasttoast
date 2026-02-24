extends Skill
class_name Berserk

const ItemDB = preload("res://db/ItemDB.gd")  # поправь путь, если другой

@export var duration: float = 10.0
@export var prefer_empty_bottle: bool = true
@export var inebriation_cost: int = 1

func _init() -> void:
	# если нужен свой КД — раскомментируй
	# cooldown = 10.0
	pass

func can_use(user: Node) -> bool:
	if user == null:
		return false

	var tree: SceneTree = user.get_tree()
	if tree == null:
		return false

	# --- Инвентарь: пустая или полная бутылка
	var inv: Node = tree.root.get_node_or_null("Inventory")
	if inv == null:
		return false

	var empty_cnt: int = int(inv.call("get_count", ItemDB.EMPTY_BOTTLE))
	var full_cnt: int  = int(inv.call("get_count", ItemDB.FULL_BOTTLE))
	var have_bottle := (empty_cnt + full_cnt) > 0
	if not have_bottle:
		return false

	# --- Ресурсы: inebriation
	var res: Node = tree.root.get_node_or_null("Resources")
	if res == null or not res.has_method("get"):
		return false
	var v = res.get("inebriation")
	if v == null:
		return false
	return int(v) >= inebriation_cost

func execute(user: Node) -> void:
	if user == null:
		return
	# Повторная проверка и сама оплата — здесь.
	var tree: SceneTree = user.get_tree()
	if tree == null:
		return

	var inv: Node = tree.root.get_node_or_null("Inventory")
	var res: Node = tree.root.get_node_or_null("Resources")
	if inv == null or res == null:
		return

	# 1) Выбор, что тратить: EMPTY предпочтительно (или наоборот, если выключишь prefer_empty_bottle)
	var empty_cnt: int = int(inv.call("get_count", ItemDB.EMPTY_BOTTLE))
	var full_cnt: int  = int(inv.call("get_count", ItemDB.FULL_BOTTLE))
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

	# 2) Проверяем inebriation ещё раз
	if not res.has_method("get") or not res.has_method("set"):
		return
	var v = res.get("inebriation")
	if v == null:
		return
	var cur_ineb := int(v)
	if cur_ineb < inebriation_cost:
		return

	# 3) Списываем бутылку (сначала бутылку — чтобы при фейле мы просто выйдем, ничего не меняя в ресурсах)
	var took: bool = bool(inv.call("take", spend_id, 1))
	if not took:
		return

	# 4) Списываем inebriation
	res.set("inebriation", cur_ineb - inebriation_cost)

	# 5) Запуск скилла: Player сам проиграет анимацию "berserk" и повесит бафф
	if user.has_method("berserk_start"):
		user.berserk_start(duration)
