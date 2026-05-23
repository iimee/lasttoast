extends RefCounted

# -------------------------
# Pool Sync
# -------------------------
func bind_hp_to_inebriation_pool(player: Node) -> void:
	var res: Node = player._res_node()
	if res == null:
		player.hp = clampi(player.hp_max, 1, 999)
		player.health_changed.emit(player.hp, player.hp_max)
		return

	var max_ineb: int = int(res.get("max_inebriation"))
	player.hp_max = max(1, max_ineb)
	if res.has_signal("inebriation_changed") and not res.is_connected("inebriation_changed", Callable(player, "_on_inebriation_pool_changed")):
		res.connect("inebriation_changed", Callable(player, "_on_inebriation_pool_changed"))
	player._on_inebriation_pool_changed(int(res.get("inebriation")))

func _emit_health_changed(player: Node) -> void:
	player.health_changed.emit(player.hp, player.hp_max)

func on_inebriation_pool_changed(player: Node, v: int) -> void:
	var prev_hp: int = player.hp
	var new_hp: int = clampi(v, 0, player.hp_max)
	if new_hp == player.hp:
		return
	player.hp = new_hp
	_emit_health_changed(player)
	if player.hp != prev_hp:
		player._maybe_start_frenzy_from_pool()

func set_hp_pool(player: Node, target_value: int) -> void:
	var prev_hp: int = player.hp
	var new_hp: int = clampi(target_value, 0, player.hp_max)
	if new_hp == player.hp:
		return
	player.hp = new_hp
	_emit_health_changed(player)
	if player.hp != prev_hp:
		player._maybe_start_frenzy_from_pool()

	var res: Node = player._res_node()
	if res == null:
		return
	var cur_ineb: int = int(res.get("inebriation"))
	var delta: int = new_hp - cur_ineb
	if delta != 0:
		res.call("add_inebriation", delta)

# -------------------------
# Costs / Healing
# -------------------------
func can_pay_hp_cost(player: Node, cost: int) -> bool:
	var c: int = max(0, cost)
	if c <= 0:
		return true
	if player._dead:
		return false
	return player.hp > c

func spend_skill_hp(player: Node, cost: int) -> bool:
	var c: int = max(0, cost)
	if c <= 0:
		return true
	if not can_pay_hp_cost(player, c):
		return false
	set_hp_pool(player, player.hp - c)
	if player.hp <= 0:
		player._die()
	return not player._dead

func gain_skill_hp(player: Node, amount: int) -> int:
	var add: int = max(0, amount)
	if add <= 0 or player._dead:
		return 0
	var prev: int = player.hp
	set_hp_pool(player, player.hp + add)
	return player.hp - prev
