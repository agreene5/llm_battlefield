extends Node

const SPEED = 4.5
const MOVE_DURATION = 15.0  # Move for 15 seconds

var active = false
var parent
var start_time = 0.0
var random_direction = Vector3.ZERO
var nav_agent

func _ready():
	parent = get_parent()
	nav_agent = parent.get_node("NavigationAgent3D")

func _process(delta):
	if not active:
		return
	
	# Check if we've reached the time limit
	if active and (Time.get_ticks_msec() / 1000.0 - start_time >= MOVE_DURATION):
		stop()
		Global_Variables.pass_enviroment_to_teammate()
		get_parent().default_behavior_start()
		return
	
	# Continue moving in the random direction
	move_in_direction(delta)

func move_in_direction(delta):
	# Set velocity based on random direction
	parent.velocity = random_direction * SPEED
	
	# Make character face the direction of movement
	if random_direction.length() > 0.01:
		var target_pos = Vector3(
			parent.global_position.x + random_direction.x,
			parent.global_position.y,
			parent.global_position.z + random_direction.z
		)
		parent.look_at(target_pos, Vector3.UP)

func generate_random_direction():
	# Generate a random angle in radians
	var angle = randf() * 2.0 * PI
	
	# Create a normalized direction vector
	random_direction = Vector3(cos(angle), 0, sin(angle)).normalized()
	
	# Check if the direction is valid using navigation
	validate_direction()

func validate_direction():
	# Project a point some distance away in the random direction
	var test_point = parent.global_position + random_direction * 5.0
	
	# Use navigation to check if this is a valid direction
	nav_agent.set_target_position(test_point)
	
	# If navigation can't find a path, try another direction
	if nav_agent.is_navigation_finished():
		generate_random_direction()  # Try again with a new direction

func start():
	active = true
	start_time = Time.get_ticks_msec() / 1000.0  # Record start time in seconds
	generate_random_direction()

func stop():
	active = false
	parent.velocity = Vector3.ZERO
