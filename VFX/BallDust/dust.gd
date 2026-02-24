extends AnimatedSprite2D

@export var duration: float = 0.5
@onready var dusttimer = $DustTimer

func _ready() -> void:
	dusttimer.wait_time = duration
	dusttimer.start()


func _on_dust_timer_timeout() -> void:
	queue_free()
