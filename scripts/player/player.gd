extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var FALL_TRANSITION_TIME: float = animated_sprite_2d.sprite_frames.get_frame_count("fall_transition") / animated_sprite_2d.sprite_frames.get_animation_speed("fall_transition")
@export var SPEED: float = 200.0
@export var JUMP_VELOCITY: float = -300.0

enum Anim_State {Idle, Walk, Run, Jump, Fall, Fall_Transition}
enum Action {None, Jump, Attack, Roll, Dash}

var queued_action: Action = Action.None
var queued_action_time: int = 0
var current_anim_state: Anim_State = Anim_State.Idle

func _process(delta: float) -> void:
	animate_player()

func _physics_process(delta: float) -> void:
	player_idle(delta)
	player_move(delta)
	player_jump_and_fall(delta)
	
	move_and_slide()

func player_idle(delta: float) -> void:
	if is_on_floor():
		current_anim_state = Anim_State.Idle
	
func player_move(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		current_anim_state = Anim_State.Run
		animated_sprite_2d.flip_h = false if direction > 0 else true
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func animate_player() -> void:
	if current_anim_state == Anim_State.Idle:
		animated_sprite_2d.play("idle")
	elif current_anim_state == Anim_State.Run:
		animated_sprite_2d.play("run")
	elif current_anim_state == Anim_State.Jump:
		animated_sprite_2d.play("jump")
	elif current_anim_state == Anim_State.Fall_Transition:
		animated_sprite_2d.play("fall_transition")
	elif current_anim_state == Anim_State.Fall:
		animated_sprite_2d.play("fall")

func player_jump_and_fall(delta: float) -> void:
	# In air
	if not is_on_floor():
		# Add gravity
		velocity += get_gravity() * delta
		
		# Set jump animation until equilibrium
		if velocity.y < -(get_gravity().y * FALL_TRANSITION_TIME)/2:
			current_anim_state = Anim_State.Jump
		# Set transition animation at equilibrium
		elif velocity.y < (get_gravity().y * FALL_TRANSITION_TIME)/2:
			current_anim_state = Anim_State.Fall_Transition
		# Set fall animation when falling
		else:
			current_anim_state = Anim_State.Fall
		
		# Queue jump if still in the air
		if Input.is_action_just_pressed("jump"):
			queued_action = Action.Jump
			queued_action_time = Time.get_ticks_msec()
	# On ground
	else:
		# Jump
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
		# Queued jump
		if queued_action == Action.Jump and Time.get_ticks_msec() - queued_action_time < 100:
			velocity.y = JUMP_VELOCITY
			queued_action = Action.None
