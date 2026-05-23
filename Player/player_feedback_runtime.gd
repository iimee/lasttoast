extends RefCounted

# -------------------------
# Camera
# -------------------------
func cache_camera(player: Node) -> void:
	if player.has_node("Camera2D"):
		player._camera_cached = player.get_node("Camera2D") as Camera2D
	else:
		player._camera_cached = null
	if player._camera_cached:
		player._camera_base_offset = player._camera_cached.offset

func camera(player: Node) -> Camera2D:
	if player._camera_cached != null and is_instance_valid(player._camera_cached):
		return player._camera_cached
	cache_camera(player)
	return player._camera_cached

func start_camera_shake(player: Node, strength_px: float, duration: float) -> void:
	if strength_px <= 0.0 or duration <= 0.0:
		return
	var cam: Camera2D = camera(player)
	if cam == null:
		return
	player._camera_shake_amp = maxf(player._camera_shake_amp, strength_px)
	player._camera_shake_dur = maxf(player._camera_shake_dur, duration)
	player._camera_shake_time = player._camera_shake_dur
	player._camera_base_offset = cam.offset

func _reset_camera_shake(player: Node, cam: Camera2D) -> void:
	cam.offset = player._camera_base_offset
	player._camera_shake_amp = 0.0
	player._camera_shake_dur = 0.0

func update_camera_shake(player: Node, delta: float) -> void:
	var cam: Camera2D = camera(player)
	if cam == null:
		return
	if player._camera_shake_time <= 0.0:
		if cam.offset != player._camera_base_offset:
			cam.offset = player._camera_base_offset
		return

	player._camera_shake_time = maxf(0.0, player._camera_shake_time - delta)
	var t: float = player._camera_shake_time / maxf(0.0001, player._camera_shake_dur)
	var amp: float = player._camera_shake_amp * t
	cam.offset = player._camera_base_offset + Vector2(
		randf_range(-amp, amp),
		randf_range(-amp, amp)
	)
	if player._camera_shake_time <= 0.0:
		_reset_camera_shake(player, cam)

# -------------------------
# Hitstop
# -------------------------
func start_hitstop(player: Node, duration: float, time_scale: float) -> void:
	if duration <= 0.0:
		return
	var scale: float = clampf(time_scale, 0.01, 1.0)
	player._hitstop_token += 1
	var token: int = player._hitstop_token
	Engine.time_scale = minf(Engine.time_scale, scale)
	await player.get_tree().create_timer(duration, true, false, true).timeout
	if token == player._hitstop_token:
		Engine.time_scale = 1.0
