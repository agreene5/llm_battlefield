extends Node

const SPEED = 4.0
const STOP_DISTANCE = 2.0

var active = false
var parent
var nav_agent
var nearest_health_box = null
var current_action = ""
var timer = null
var has_stopped = false
var initial_connection = true  # Flag to track initial connection

func _ready():
	parent = get_parent()
	nav_agent = parent.get_node("NavigationAgent3D")
	
	# Create a timer for the 60-second check
	timer = Timer.new()
	timer.wait_time = 30.0
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
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
	# Reset the timer by stopping and restarting it if active
	if active and not has_stopped:
		timer.stop()
		timer.start()

func _on_timer_timeout():
	if active and not has_stopped:
		# Call the function after 60 seconds if still active
		Global_Variables.pass_enviroment_to_teammate()
		get_parent().default_behavior_start()

func _process(delta):
	if not active:
		return
			
	process_movement(delta)

func find_nearest_health_box():
	var shortest_distance = INF
	nearest_health_box = null
	
	# Get all health boxes in the scene
	var health_boxes = parent.get_tree().get_nodes_in_group("Weapon_Box")
	
	for health_box in health_boxes:
		var distance = parent.global_position.distance_to(health_box.global_position)
		if distance < shortest_distance:
			shortest_distance = distance
			nearest_health_box = health_box
	
	return nearest_health_box

func process_movement(delta):
	parent.velocity = Vector3.ZERO
	
	# Find the nearest health box
	find_nearest_health_box()
	
	if nearest_health_box == null:
		return
	
	var distance = parent.global_position.distance_to(nearest_health_box.global_position)
	
	# If not within stopping distance, move towards the health box
	if distance > STOP_DISTANCE:
		# Set animation state to running
		if parent.has_node("AnimationTree"):
			parent.anim_tree.set("parameters/conditions/run", true)
			parent.anim_tree.set("parameters/conditions/attack", false)
				
		nav_agent.set_target_position(nearest_health_box.global_position)
		var next_nav_point = nav_agent.get_next_path_position()
		parent.velocity = (next_nav_point - parent.global_transform.origin).normalized() * SPEED
		parent.look_at(Vector3(parent.global_position.x + parent.velocity.x, parent.global_position.y, parent.global_position.z + parent.velocity.z), Vector3.UP)
	# If within stopping distance, perform the appropriate action
	elif active:
		# Set animation state to idle (not running)
		if parent.has_node("AnimationTree"):
			parent.anim_tree.set("parameters/conditions/run", false)
				
		stop()
		if current_action == "pick_up":
			$"../ItemPickUpper".start()
		elif current_action == "equip":
			$"../ItemEquipper".start()

func should_run():
	if nearest_health_box:
		var distance = parent.global_position.distance_to(nearest_health_box.global_position)
		return distance > STOP_DISTANCE
	return false

func has_target():
	return nearest_health_box != null

func get_target_position():
	if nearest_health_box:
		return nearest_health_box.global_position
	return parent.global_position

func start(action = ""):
	current_action = action
	active = true
	has_stopped = false
	
	# Start the 60-second timer
	timer.start()
	
	# Override the main character's animation state machine control
	if parent.has_node("AnimationTree"):
		parent.state_machine = parent.anim_tree.get("parameters/playback")
		parent.state_machine.travel("Sword_Run")

func stop():
	active = false
	has_stopped = true
	
	# Stop the timer when behavior is stopped
	timer.stop()
