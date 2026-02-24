extends Area2D
# Лужа огня: задержка старта, тики урона, апдрафт.
# LANE:
# - урон только по lane_index (если lane_index задан)
# - визуальный offset по lane (смещаем ТОЛЬКО спрайт, физика остаётся в центре)

@export var damage_per_tick: int = 1
@export var tick_interval: float = 0.4
@export var lifetime: float = 5.0
@export var start_delay: float = 0.15
@export var enemy_group: String = "Enemy"
@export var affect_player: bool = true

@export var produces_updraft: bool = true
@export var updraft_strength: float = 60.0
@export var updraft_only_when_active: bool = true

@onready var sprite: AnimatedSprite2D = (get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D)

var _tick_timer: Timer
var _life_timer: Timer
var _delay_timer: Timer
var _active: bool = false

var _players_inside: Array = []

# ===== lane =====
var lane_index: int = -1
var depth_y: float = 0.0
var _sprite_base_y: float = 0.0


func _ready() -> void:
	set_physics_process(true)

	monitoring = false
	monitorable = true
	visible = false
	add_to_group("vfx")
	add_to_group("Hazard")

	# запоминаем базовую позицию спрайта (если у него уже есть оффсет)
	if sprite != null:
		_sprite_base_y = sprite.position.y
	_apply_lane_visual()

	# loop anim
	if sprite != null and sprite.sprite_frames != null:
		var anim_name: String = sprite.animation if sprite.animation != "" else "default"
		if sprite.sprite_frames.has_animation(anim_name):
			sprite.sprite_frames.set_animation_loop(anim_name, true)

	# delay
	_delay_timer = Timer.new()
	_delay_timer.one_shot = true
	_delay_timer.wait_time = max(0.0, start_delay)
	_delay_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_delay_timer.ignore_time_scale = true
	add_child(_delay_timer)
	_delay_timer.timeout.connect(_activate_fire)
	_delay_timer.start()

	# tick
	_tick_timer = Timer.new()
	_tick_timer.wait_time = tick_interval
	_tick_timer.autostart = false
	_tick_timer.one_shot = false
	add_child(_tick_timer)
	_tick_timer.timeout.connect(_apply_tick)

	# life
	_life_timer = Timer.new()
	_life_timer.wait_time = lifetime
	_life_timer.one_shot = true
	add_child(_life_timer)
	_life_timer.timeout.connect(queue_free)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


# ===== lane API =====
func set_lane(lane: int) -> void:
	lane_index = lane
	depth_y = LaneSystem.center_from_lane(lane_index)
	_apply_lane_visual()

func set_lane_index(i: int) -> void:
	# ВАЖНО: MolotovFly зовёт именно это
	set_lane(i)

func set_depth_y(v: float) -> void:
	depth_y = v
	_apply_lane_visual()

func _apply_lane_visual() -> void:
	# lane визуальный → смещаем только спрайт
	if sprite != null:
		sprite.position.y = _sprite_base_y + depth_y


func _activate_fire() -> void:
	_active = true
	visible = true
	monitoring = true

	if sprite != null and sprite.sprite_frames != null:
		var anim_name: String = sprite.animation if sprite.animation != "" else "default"
		if sprite.sprite_frames.has_animation(anim_name):
			sprite.play(anim_name)

	_refresh_players_inside()
	_tick_timer.start()
	_life_timer.start()


func _physics_process(_delta: float) -> void:
	if not produces_updraft:
		return
	if updraft_only_when_active and not _active:
		return
	if not monitoring:
		return

	for body in _players_inside:
		if body and is_instance_valid(body) and body.has_method("apply_updraft"):
			body.call("apply_updraft", updraft_strength)


func _apply_tick() -> void:
	if not _active:
		return

	var bodies: Array = get_overlapping_bodies()
	for body in bodies:
		if body == null or not is_instance_valid(body):
			continue

		var is_enemy: bool = body.is_in_group(enemy_group)
		var is_player: bool = body.is_in_group("Player")
		if not is_enemy and not (affect_player and is_player):
			continue

		# ===== lane filter (как у BottleFly) =====
		var t_lane: int = _get_target_lane(body)
		if lane_index != -1 and t_lane != -1 and t_lane != lane_index:
			continue

		if body.has_method("apply_damage"):
			var knock := Vector2(0, -40)
			# третий аргумент — источник (self), как у тебя было
			body.call("apply_damage", damage_per_tick, knock, self)


func _get_target_lane(target: Node) -> int:
	if target == null:
		return -1

	if target is Object:
		var to := target as Object

		# 1) target.lane_body.lane_index
		var lb = to.get("lane_body")
		if lb != null and lb is Object:
			var lbo := lb as Object
			var li = lbo.get("lane_index")
			if typeof(li) == TYPE_INT:
				return int(li)

		# 2) target.lane_index
		var li2 = to.get("lane_index")
		if typeof(li2) == TYPE_INT:
			return int(li2)

	return -1


func _on_body_entered(body: Node) -> void:
	if not produces_updraft:
		return
	if not body.is_in_group("Player"):
		return
	if _players_inside.find(body) == -1:
		_players_inside.append(body)
		if _active and body.has_method("apply_updraft"):
			body.call("apply_updraft", updraft_strength)


func _on_body_exited(body: Node) -> void:
	var idx := _players_inside.find(body)
	if idx != -1:
		_players_inside.remove_at(idx)


func _refresh_players_inside() -> void:
	_players_inside.clear()
	var bodies: Array = get_overlapping_bodies()
	for body in bodies:
		if body and is_instance_valid(body) and body.is_in_group("Player"):
			_players_inside.append(body)


func place_on_surface(hit_position: Vector2, surface_normal: Vector2) -> void:
	# Физическая позиция (центр), визуальный lane — отдельно через depth_y
	global_position = hit_position
	rotation = surface_normal.angle() + PI / 2.0
	_apply_lane_visual()
