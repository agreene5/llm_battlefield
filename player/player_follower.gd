extends Node

const SPEED = 3.0
const CLOSE_RANGE = 2.0    # Range to get within initially
const FAR_RANGE = 6.0      # Only start following again if beyond this range
const TIMEOUT_DURATION = 30.0  # 1 minute timeout

var active = false
var parent
var nav_agent
var start_time = 0.0       # Track when start() was called
var goal_reached = false   # Track if we've reached the player
var in_idle_zone = false   # Tracks if we're in the "idle zone" between CLOSE_RANGE and FAR_RANGE
var initial_connection = true  # Flag to track initial connection

func _ready():
		parent = get_parent()
		nav_agent = parent.get_node("NavigationAgent3D")
		
		# Connect to the environment_updated signal
		Global_Variables.environment_updated.connect(_on_environment_updated)
		
func _on_environment_updated(info):
		# Skip the first signal emission that happens during initialization
		if initial_connection:
				initial_connection = false
				return
		
		# Reset the timer when environment is updated
		reset_timer()

func reset_timer():
		if active:
				# Reset the start time to now
				start_time = Time.get_ticks_msec() / 1000.0

func _process(delta):
		if not active:
				return
		
		# Check if we've timed out without reaching the player
		if active and !goal_reached and (Time.get_ticks_msec() / 1000.0 - start_time >= TIMEOUT_DURATION):
				Global_Variables.pass_enviroment_to_teammate()
				get_parent().default_behavior_start()
				stop()
				return
		
		process_movement(delta)

func process_movement(delta):
		var distance = get_distance_to_player()
		
		# Determine if we should be moving or idle based on distance and current state
		if distance <= CLOSE_RANGE:
				# We've reached the close range - enter idle zone
				if !goal_reached:
						goal_reached = true
						get_parent().default_behavior_start()
						await get_tree().create_timer(5.0).timeout
						Global_Variables.pass_enviroment_to_teammate()
				
				in_idle_zone = true
				parent.velocity = Vector3.ZERO
				face_player()
		elif distance > FAR_RANGE:
				# Player has moved too far away - exit idle zone and start following
				in_idle_zone = false
				move_to_player(delta)
		elif in_idle_zone:
				# Player is between CLOSE_RANGE and FAR_RANGE, but we're already in idle zone
				# So stay idle until they go beyond FAR_RANGE
				parent.velocity = Vector3.ZERO
				face_player()
		else:
				# Player is between CLOSE_RANGE and FAR_RANGE, but we're not in idle zone yet
				# So keep moving until we reach CLOSE_RANGE
				move_to_player(delta)

func move_to_player(delta):
		if Global_Variables.player_position:
				nav_agent.set_target_position(Global_Variables.player_position)
				var next_nav_point = nav_agent.get_next_path_position()
				
				# Calculate movement direction
				var direction = (next_nav_point - parent.global_position).normalized()
				
				# Set velocity
				parent.velocity = direction * SPEED
				
				# Correct facing direction
				if direction.length() > 0.01:
						# Use proper look_at function to face the direction of movement
						var target_pos = Vector3(
								parent.global_position.x + direction.x,
								parent.global_position.y,
								parent.global_position.z + direction.z
						)
						parent.look_at(target_pos, Vector3.UP)

func get_distance_to_player():
		if Global_Variables.player_position:
				return parent.global_position.distance_to(Global_Variables.player_position)
		return 0.0

func face_player():
		if Global_Variables.player_position:
				# Look at player position but keep y-position the same
				var target_pos = Vector3(
						Global_Variables.player_position.x,
						parent.global_position.y,
						Global_Variables.player_position.z
				)
				parent.look_at(target_pos, Vector3.UP)

func should_run():
		if !active:
				return false
		
		var distance = get_distance_to_player()
		return (distance > CLOSE_RANGE || (!in_idle_zone && distance <= FAR_RANGE))

func is_player_in_range():
		return get_distance_to_player() < CLOSE_RANGE

func start():
		active = true
		in_idle_zone = false  # Start in "following" mode
		goal_reached = false  # Reset goal tracking
		start_time = Time.get_ticks_msec() / 1000.0  # Record start time in seconds

func stop():
		active = false
		parent.velocity = Vector3.ZERO
		in_idle_zone = false
