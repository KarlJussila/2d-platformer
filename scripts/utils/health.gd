extends Node2D

signal health_changed (new_health: int)

@export var max_health = 100
var health = max_health

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health = max_health

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func take_damage(damage: int) -> int:
	health = max(0, health - damage)
	emit_signal("health_changed", health)
	return health