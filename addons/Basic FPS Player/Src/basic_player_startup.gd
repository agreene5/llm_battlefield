@tool
extends CharacterBody3D

var BasicFPSPlayerScene : PackedScene = preload("basic_player_head.tscn")
var addedHead = false
var typing_mode_active = false # Still needed to track state, but controlled externally

func _enter_tree():
		if find_child("Head"):
				addedHead = true
		
		if Engine.is_editor_hint() && !addedHead:
				var s = BasicFPSPlayerScene.instantiate()
				add_child(s)
				s.owner = get_tree().edited_scene_root
				addedHead = true

## PLAYER MOVMENT SCRIPT ##
###########################

@export_category("Mouse Capture")
@export var CAPTURE_ON_START := true

@export_category("Movement")
@export_subgroup("Settings")
@export var SPEED := 5.0
@export var SPRINT_MULTIPLIER := 1.5
@export var ACCEL := 50.0
@export var IN_AIR_SPEED := 3.0
@export var IN_AIR_ACCEL := 5.0
@export var JUMP_VELOCITY := 4.5
@export_subgroup("Gliding")
@export var GLIDE_GRAVITY_MULTIPLIER := 0.1
@export var GLIDE_SPEED_MULTIPLIER := 4.0
@export var AIR_TIME_BEFORE_GLIDE := 0.3
@export_subgroup("Head Bob")
@export var HEAD_BOB := true
@export var HEAD_BOB_FREQUENCY := 0.3
@export var HEAD_BOB_AMPLITUDE := 0.01
@export_subgroup("Clamp Head Rotation")
@export var CLAMP_HEAD_ROTATION := true
@export var CLAMP_HEAD_ROTATION_MIN := -90.0
@export var CLAMP_HEAD_ROTATION_MAX := 90.0

@export_category("Key Binds")
@export_subgroup("Mouse")
@export var MOUSE_ACCEL := true
@export var KEY_BIND_MOUSE_SENS := 0.005
@export var KEY_BIND_MOUSE_ACCEL := 50
@export_subgroup("Movement")
@export var KEY_BIND_UP := "ui_up"
@export var KEY_BIND_LEFT := "ui_left"
@export var KEY_BIND_RIGHT := "ui_right"
@export var KEY_BIND_DOWN := "ui_down"
@export var KEY_BIND_JUMP := "ui_accept"
@export var KEY_BIND_SPRINT := "ui_shift" # Added sprint key bind

@export_category("Advanced")
@export var UPDATE_PLAYER_ON_PHYS_STEP := true  # When check player is moved and rotated in _physics_process (fixed fps)
																																																# Otherwise player is updated in _process (uncapped)

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
# To keep track of current speed and acceleration
var speed = SPEED
var accel = ACCEL
var is_sprinting = false
var is_gliding = false
var air_time = 0.0

# Used when lerping rotation to reduce stuttering when moving the mouse
var rotation_target_player : float
var rotation_target_head : float

# Used when bobing head
var head_start_pos : Vector3

# Current player tick, used in head bob calculation
var tick = 0

func _ready():
		if Engine.is_editor_hint():
				return

		# Capture mouse if set to true
		if CAPTURE_ON_START:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

		head_start_pos = $Head.position
		
		# Make sure the sprint action exists
		if not InputMap.has_action(KEY_BIND_SPRINT):
				InputMap.add_action(KEY_BIND_SPRINT)
				var event = InputEventKey.new()
				event.keycode = KEY_SHIFT
				InputMap.action_add_event(KEY_BIND_SPRINT, event)

func _physics_process(delta):
		if Engine.is_editor_hint():
				return
		
		# Skip movement processing if typing mode is active
		if typing_mode_active:
				return
		
		# Increment player tick, used in head bob motion
		tick += 1
		
		if UPDATE_PLAYER_ON_PHYS_STEP:
				move_player(delta)
				rotate_player(delta)
		
		if HEAD_BOB:
				# Only move head when on the floor and moving
				if velocity && is_on_floor():
						head_bob_motion()
				reset_head_bob(delta)

func _process(delta):
		if Engine.is_editor_hint():
				return

		# Skip movement processing if typing mode is active
		if typing_mode_active:
				return
				
		if !UPDATE_PLAYER_ON_PHYS_STEP:
				move_player(delta)
				rotate_player(delta)

func _input(event):
		if Engine.is_editor_hint():
				return
		
		# Skip mouse processing if typing mode is active
		if typing_mode_active:
				return
				
		# Listen for mouse movement and check if mouse is captured
		if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				set_rotation_target(event.relative)

# Set typing mode from external controller
func set_typing_mode(is_active):
		typing_mode_active = is_active

# Rest of the functions (set_rotation_target, rotate_player, move_player, etc.) remain the same
func set_rotation_target(mouse_motion : Vector2):
		# Add player target to the mouse -x input
		rotation_target_player += -mouse_motion.x * KEY_BIND_MOUSE_SENS
		# Add head target to the mouse -y input
		rotation_target_head += -mouse_motion.y * KEY_BIND_MOUSE_SENS
		# Clamp rotation
		if CLAMP_HEAD_ROTATION:
				rotation_target_head = clamp(rotation_target_head, deg_to_rad(CLAMP_HEAD_ROTATION_MIN), deg_to_rad(CLAMP_HEAD_ROTATION_MAX))
		
func rotate_player(delta):
		if MOUSE_ACCEL:
				# Shperical lerp between player rotation and target
				quaternion = quaternion.slerp(Quaternion(Vector3.UP, rotation_target_player), KEY_BIND_MOUSE_ACCEL * delta)
				# Same again for head
				$Head.quaternion = $Head.quaternion.slerp(Quaternion(Vector3.RIGHT, rotation_target_head), KEY_BIND_MOUSE_ACCEL * delta)
		else:
				# If mouse accel is turned off, simply set to target
				quaternion = Quaternion(Vector3.UP, rotation_target_player)
				$Head.quaternion = Quaternion(Vector3.RIGHT, rotation_target_head)
		
func move_player(delta):
		# Track if we're on the floor
		var was_on_floor = is_on_floor()
		
		# Check if not on floor
		if not is_on_floor():
				# Track air time
				air_time += delta
				
				# Reduce speed and accel
				speed = IN_AIR_SPEED
				accel = IN_AIR_ACCEL
				
				# Apply gravity based on gliding state
				if is_gliding:
						velocity.y -= gravity * GLIDE_GRAVITY_MULTIPLIER * delta
				else:
						velocity.y -= gravity * delta
		else:
				# Reset air time and gliding when on floor
				air_time = 0.0
				if is_gliding:
						is_gliding = false
				
				# Set speed and accel to default
				speed = SPEED
				accel = ACCEL

		# Check for glide activation
		if Input.is_action_just_pressed(KEY_BIND_JUMP):
				if not is_on_floor():
						if is_gliding:
								# Disable gliding if already gliding
								is_gliding = false
						elif air_time >= AIR_TIME_BEFORE_GLIDE:
								# Enable gliding if in air long enough
								is_gliding = false
				elif is_on_floor():
						# Regular jump
						velocity.y = JUMP_VELOCITY

		# Check if sprinting
		is_sprinting = Input.is_action_pressed(KEY_BIND_SPRINT)
		
		# Apply speed modifiers
		var current_speed = speed
		if is_sprinting:
				current_speed *= SPRINT_MULTIPLIER
		
		# Apply gliding speed multiplier
		if is_gliding:
				current_speed *= GLIDE_SPEED_MULTIPLIER

		# Get the input direction and handle the movement/deceleration.
		var input_dir = Input.get_vector(KEY_BIND_LEFT, KEY_BIND_RIGHT, KEY_BIND_UP, KEY_BIND_DOWN)
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		velocity.x = move_toward(velocity.x, direction.x * current_speed, accel * delta)
		velocity.z = move_toward(velocity.z, direction.z * current_speed, accel * delta)

		move_and_slide()
		
		# Reset gliding if we just landed
		if was_on_floor == false && is_on_floor() == true:
				is_gliding = false

func head_bob_motion():
		var pos = Vector3.ZERO
		pos.y += sin(tick * HEAD_BOB_FREQUENCY) * HEAD_BOB_AMPLITUDE
		pos.x += cos(tick * HEAD_BOB_FREQUENCY/2) * HEAD_BOB_AMPLITUDE * 2
		$Head.position += pos

func reset_head_bob(delta):
		# Lerp back to the staring position
		if $Head.position == head_start_pos:
				pass
		$Head.position = lerp($Head.position, head_start_pos, 2 * (1/HEAD_BOB_FREQUENCY) * delta)
