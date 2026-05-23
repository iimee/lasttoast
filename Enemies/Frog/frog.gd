extends CharacterBody2D

const SPEED = 80.0
const JUMP_VELOCITY = -400.0
const SURFACE_SLOW_MIN: float = 0.1

var direction := 1
var state := "idle"

# Гравитация из настроек проекта
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var max_hp: int = 3
@export var knockback_friction: float = 600.0  # чем больше, тем быстрее гасится нокбэк

var hp: int
var knockback_velocity: Vector2 = Vector2.ZERO
var _surface_slow_multiplier: float = 1.0
var _surface_slow_until_msec: int = 0

func apply_surface_slow(multiplier: float, duration_sec: float = 0.12) -> void:
	var m: float = clampf(multiplier, SURFACE_SLOW_MIN, 1.0)
	_surface_slow_multiplier = m
	var until: int = Time.get_ticks_msec() + int(maxf(0.0, duration_sec) * 1000.0)
	if until > _surface_slow_until_msec:
		_surface_slow_until_msec = until

func _surface_speed_multiplier() -> float:
	if _surface_slow_until_msec <= 0:
		return 1.0
	if Time.get_ticks_msec() > _surface_slow_until_msec:
		_surface_slow_until_msec = 0
		_surface_slow_multiplier = 1.0
		return 1.0
	return _surface_slow_multiplier

func _ready() -> void:
	hp = max_hp
	add_to_group("Enemy")

func _physics_process(delta: float) -> void:
	# ===== НОКБЭК ИМЕЕТ ПРИОРИТЕТ =====
	if knockback_velocity.length() > 1.0:
		velocity = knockback_velocity
		# Плавно гасим отдачу
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)

		# Анимации во время нокбэка
		if velocity.y > 0:
			$AnimatedSprite2D.play("fall")
		else:
			# если есть клип "hit" — можно сыграть его; иначе используем "jump"
			if $AnimatedSprite2D.sprite_frames and $AnimatedSprite2D.sprite_frames.has_animation("hit"):
				$AnimatedSprite2D.play("hit")
			else:
				$AnimatedSprite2D.play("jump")

	else:
		# ===== ТВОЯ БАЗОВАЯ ЛОГИКА =====
		if is_on_floor():
			# stop if is on the floor
			velocity.x = 0
			$AnimatedSprite2D.play("idle")
		else:
			# Add the gravity and move horizontally if in air.
			velocity.x = direction * SPEED * _surface_speed_multiplier()
			velocity.y += gravity * delta
			if velocity.y > 0:
				$AnimatedSprite2D.play("fall")
			else:
				$AnimatedSprite2D.play("jump")

	move_and_slide()

	# flip sprite (ориентируемся по направлению; при нокбэке — по текущей скорости)
	if knockback_velocity.length() > 1.0:
		$AnimatedSprite2D.flip_h = velocity.x < 0
	else:
		$AnimatedSprite2D.flip_h = direction > 0

func jump() -> void:
	velocity.y = JUMP_VELOCITY

func _on_timer_timeout() -> void:
	# when timer finish, change direction and jump
	direction *= -1
	jump()

func apply_damage(dmg: int, kb: Vector2, source_pos: Vector2) -> void:
	hp -= max(0, dmg)
	knockback_velocity = kb
	if hp <= 0:
		die()

func die() -> void:
	queue_free()
