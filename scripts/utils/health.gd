extends Node2D

signal health_changed (new_health: int)

@export var max_health = 100
var health = max_health

# Called when the node enters the scene tree for the first time
func _ready() -> void:
	health = max_health

func take_damage(damage: int, negative: bool = false) -> int:
	# Return current health if no damage is taken
	if not damage: return health

	# Deal damage
	if negative:
		health = health - damage
	else:
		health = max(0, health - damage)
	
	# Emit health change signal and return new health
	emit_signal("health_changed", health)
	return health

func heal(amount: int, overheal: bool = false) -> int:
	# Return current health if no healing is done
	if not amount: return health

	# Heal
	if overheal:
		health = health + amount
	else:
		health = min(max_health, health + amount)
	
	# Emit health change signal and return new health
	emit_signal("health_changed", health)
	return health

func set_health(new_health: int) -> int:
	# Return current health if no change is made
	if new_health == health: return health

	# Update health and emit signal
	health = new_health
	emit_signal("health_changed", health)
	return health