extends CharacterBody2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_player: AnimationPlayer = $AnimationPlayer

enum Action {None, Jump, Attack, Roll, Dash}
var queued_action_priority: Dictionary = {Action.Dash: 4, Action.Roll: 3, Action.Attack: 2, Action.Jump: 1, Action.None: 0}
var interruptable_actions: Array[Action] = [Action.None, Action.Jump]
var queued_action_duration: Dictionary = {Action.None: 0, Action.Jump: 100, Action.Attack: 200, Action.Roll: 100, Action.Dash: 100}

@export var jump_velocity: float = -250.0
@export var acceleration: float = 1200.0
@export var friction: float = 9
@export var lurch_velocity: float = 600
var animation_state: StringName = "idle"
var active_action: Action = Action.None

var can_run: bool = true
var can_turn: bool = true
var gravity_enabled: bool = true

var queued_action: Action = Action.None
var queued_action_time: int = 0

var facing: int = 1

func _process(_delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	_handle_attack()
	_move(delta)
	move_and_slide()
	_update_animations()

# ACTIONS #
# Tries to queue an action. Fails if it lacks priority
func _queue_action(action: Action) -> bool:
	# Don't queue if it has a lower priority than the active queued action
	if _queued_action_is_active(false) and queued_action_priority[action] < queued_action_priority[queued_action]:
		return false
		
	# Otherwise, queue it
	queued_action = action
	queued_action_time = Time.get_ticks_msec()
	return true
	
func _clear_queued_action():
	queued_action = Action.None
	queued_action_time = 0

# Checks if the queued action is still active or has expired
func _queued_action_is_active(clear: bool = true) -> bool:
	var active: bool = Time.get_ticks_msec() - queued_action_time < queued_action_duration[queued_action]
	if active: return true
	if clear:
		_clear_queued_action()
	return false

func _handle_attack():
	if Input.is_action_just_pressed("attack"):
		if active_action in interruptable_actions:
			set_active_action(Action.Attack)
		else:
			_queue_action(Action.Attack)
		return
	
	if queued_action == Action.Attack and active_action in interruptable_actions:
		if _queued_action_is_active():
			set_active_action(Action.Attack)

# MOVEMENT #
func _move(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration
	var direction := Input.get_axis("move_left", "move_right")
	_move_horizontal(delta, direction)
	_move_vertical(delta)
	_handle_jump()

func _move_horizontal(delta: float, direction: float):
	# If left or right inputs are active
	if can_run and direction and (can_turn || direction == facing):
		# Accelerate
		velocity.x += direction * acceleration * delta
		
	# Decelerate
	velocity.x = move_toward(velocity.x, 0, max(10, abs(velocity.x) * friction * delta))

func _move_vertical(delta: float):
	# In air (gravity, jump queuing)
	if not is_on_floor():
		# Add gravity
		velocity += get_gravity() * delta
		
		# Queue jump
		if Input.is_action_just_pressed("jump"):
			_queue_action(Action.Jump)

func _handle_jump():
	if is_on_floor():
		# Queued jump
		if queued_action == Action.Jump:
			if _queued_action_is_active():
				velocity.y = jump_velocity
			queued_action = Action.None
			
		# Standard jump
		elif Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity

func lurch():
	if is_on_floor():
		velocity.x = lurch_velocity * facing

# ANIMATION #
func _update_animations() -> void:
	var direction := Input.get_axis("move_left", "move_right")
	
	# Set animation parameters
	var attacking: bool = active_action == Action.Attack
	animation_tree["parameters/conditions/attacking"] = attacking
	
	var attack_queued: bool = queued_action == Action.Attack and _queued_action_is_active(false)
	animation_tree["parameters/Attack/conditions/attack_queued"] = attack_queued
	
	var attack_not_queued: bool = not attack_queued
	animation_tree["parameters/Attack/conditions/attack_not_queued"] = attack_not_queued
	
	var running: bool = bool(direction)
	animation_tree["parameters/Move/conditions/running"] = running
	
	var idle: bool = not direction
	animation_tree["parameters/Move/conditions/idle"] = idle
	
	var jumping: bool = velocity.y < 0
	animation_tree["parameters/Move/conditions/jumping"] = jumping
	
	var falling: bool = _about_to_fall()
	animation_tree["parameters/Move/conditions/falling"] = falling
	
	var on_ground: bool = is_on_floor()
	animation_tree["parameters/Move/conditions/on_ground"] = on_ground
	
	# Flip player according to facing direction
	if direction and can_turn:
		# Save facing direction
		facing = sign(direction)
		
		#Flip player
		self.scale = Vector2(1,1) if direction > 0 else Vector2(1,-1)
		self.rotation = 0.0 if direction > 0 else PI

func _about_to_fall() -> bool:
	return not is_on_floor() and velocity.y >= -(get_gravity().y * animation_player.get_animation("fall_transition").length)/2

# SIGNALS #
func _on_animation_tree_animation_started(anim_name: StringName) -> void:
	animation_state = anim_name
	if animation_state in ["slash1", "slash2"] and anim_name in ["slash1", "slash2"]:
		_clear_queued_action()

# SETTERS #
func set_can_run(value: bool) -> bool:
	can_run = value
	return can_run

func set_can_turn(value: bool) -> bool:
	can_turn = value
	return can_run
	
func set_gravity_enabled(value: bool) -> bool:
	gravity_enabled = value
	return can_run
	
func set_active_action(value: Action):
	active_action = value
	_update_animations()
