extends CharacterBody2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree

@export var jump_velocity: float = -250.0
@export var acceleration: float = 1200.0
@export_range(0,1) var friction: float = 0.15

enum Action {None, Jump, Attack, Roll, Dash}

var queued_action: Action = Action.None
var queued_action_time: int = 0

func _process(_delta: float) -> void:
	_animate_player()

func _physics_process(delta: float) -> void:
	_move(delta)
	_jump_and_fall(delta)
	
	move_and_slide()
	
func _animate_player() -> void:
	# Set animation parameters
	animation_tree["parameters/conditions/running"] = bool(velocity.x)
	animation_tree["parameters/conditions/idle"] = not velocity.x
	animation_tree["parameters/conditions/jumping"] = velocity.y < 0
	animation_tree["parameters/conditions/falling"] = _about_to_fall()
	animation_tree["parameters/conditions/on_ground"] = is_on_floor()
	
	# Flip player according to facing direction
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		self.scale = Vector2(1,1) if direction > 0 else Vector2(1,-1)
		self.rotation = 0 if direction > 0.0 else PI
	
func _move(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		# Accelerate
		velocity.x += direction * acceleration * delta
		
	# Decelerate
	velocity.x = move_toward(velocity.x, 0, max(10, abs(velocity.x) * friction))

func _jump_and_fall(delta: float) -> void:
	# In air
	if not is_on_floor():
		# Add gravity
		velocity += get_gravity() * delta
		
		# Queue jump if still in the air
		if Input.is_action_just_pressed("jump"):
			queued_action = Action.Jump
			queued_action_time = Time.get_ticks_msec()
	# On ground
	else:
		# Jump
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
		# Queued jump
		if queued_action == Action.Jump and Time.get_ticks_msec() - queued_action_time < 100:
			velocity.y = jump_velocity
			queued_action = Action.None


func _about_to_fall() -> bool:
	return not is_on_floor() and velocity.y >= -(get_gravity().y * animation_player.get_animation("fall_transition").length)/2
