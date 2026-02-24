# res://VFX/Explosion.gd
extends Area2D
# Одномоментный AOE-урон.

@export var damage: int = 3
@export var knockback: float = 260
@export var lifetime: float = 0.25
@export var enemy_group: String = "Enemy"
@export var affect_player: bool = false   # если вдруг нужен урон по игроку

@onready var anim_player: AnimationPlayer = (get_node_or_null("AnimationPlayer") as AnimationPlayer)
@onready var sprite: AnimatedSprite2D = (get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D)

var _applied: bool = false

func _ready() -> void:
	monitoring = true
	monitorable = true
	add_to_group("vfx")

	# урон выдаём один раз после инициализации
	call_deferred("_apply_once")

	# анимация спрайта (если есть)
	if sprite != null and sprite.sprite_frames != null:
		var name: String = sprite.animation if sprite.animation != "" else "default"
		if sprite.sprite_frames.has_animation(name):
			sprite.sprite_frames.set_animation_loop(name, false)
			sprite.play(name)

	# анимация плеера (если есть)
	if anim_player != null:
		var list: PackedStringArray = anim_player.get_animation_list()
		if list.size() > 0:
			anim_player.play(list[0])

	# самоуничтожение по таймеру
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = lifetime
	add_child(t)
	t.timeout.connect(queue_free)
	t.start()

func _apply_once() -> void:
	if _applied:
		return
	_applied = true

	var bodies: Array = get_overlapping_bodies()  # Array[Node] ок, жёстко не типизирую ради совместимости
	for body in bodies:
		if body == null or not is_instance_valid(body):
			continue

		var is_enemy: bool = (body.is_in_group(enemy_group) or body.has_method("apply_damage"))
		var is_player: bool = body.is_in_group("Player")
		if not is_enemy and not (affect_player and is_player):
			continue

		var dir: Vector2 = (body.global_position - global_position)
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT
		else:
			dir = dir.normalized()

		if body.has_method("apply_damage"):
			body.call("apply_damage", damage, dir * float(knockback), global_position)
