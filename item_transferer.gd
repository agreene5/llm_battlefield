extends Node

const SPEED = 3.0
const TRANSFER_RANGE = 2.0
const TIMEOUT_DURATION = 30.0  # 30 seconds timeout

var active = false
var parent
var nav_agent
var item_transferred = false
var transfer_in_progress = false
var start_time = 0.0  # Track when start() was called
var initial_connection = true  # Flag to track initial connection
var animation_complete_timer = null
var transfer_complete = false

func _ready():
		parent = get_parent()
		nav_agent = parent.get_node("NavigationAgent3D")
		
		# Connect to the environment_updated signal
		Global_Variables.environment_updated.connect(_on_environment_updated)
		
		# Create timer to ensure animation completes properly
		animation_complete_timer = Timer.new()
		animation_complete_timer.one_shot = true
		animation_complete_timer.wait_time = 2.0  # Adjust based on animation length
		animation_complete_timer.timeout.connect(_on_animation_complete)
		add_child(animation_complete_timer)

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
		
		# Check for timeout condition
		if active and Time.get_ticks_msec() / 1000.0 - start_time >= TIMEOUT_DURATION:
				Global_Variables.pass_enviroment_to_teammate()
				get_parent().default_behavior_start()
				stop()
				return
		
		if transfer_complete:
				# After transferring, pass environment and return
				Global_Variables.pass_enviroment_to_teammate()
				get_parent().default_behavior_start()
				stop()
				return
		
		process_movement(delta)

func process_movement(delta):
		parent.velocity = Vector3.ZERO
		
		if is_player_in_range() and !transfer_in_progress:
				# Stop moving and look at player
				parent.velocity = Vector3.ZERO
				face_player()
				
				# Start transfer
				if !transfer_in_progress:
						start_transfer()
		elif !transfer_in_progress:
				# Move towards player
				if Global_Variables.player_position:
						nav_agent.set_target_position(Global_Variables.player_position)
						var next_nav_point = nav_agent.get_next_path_position()
						parent.velocity = (next_nav_point - parent.global_transform.origin).normalized() * SPEED
						parent.look_at(Vector3(parent.global_position.x + parent.velocity.x, 
																parent.global_position.y, 
																parent.global_position.z + parent.velocity.z), Vector3.UP)

func is_player_in_range():
		if Global_Variables.player_position:
				var distance = parent.global_position.distance_to(Global_Variables.player_position)
				return distance < TRANSFER_RANGE
		return false

func face_player():
		if Global_Variables.player_position:
				parent.look_at(Global_Variables.player_position, Vector3.UP)

func _on_animation_complete():
		if active and transfer_in_progress:
				# Complete the transfer
				if Global_Variables.teammate_item != null and !item_transferred:
						Global_Variables.hand_player_item(Global_Variables.teammate_item)
						item_transferred = true
				
				transfer_in_progress = false
				
				# Wait briefly before finishing
				await parent.get_tree().create_timer(0.5).timeout
				transfer_complete = true

func start_transfer():
		if transfer_in_progress:
				return
				
		transfer_in_progress = true
		
		# Start the animation complete timer
		animation_complete_timer.start()

func should_run():
		# This is checked by the main update_animations function
		return active && !is_player_in_range() && !transfer_in_progress && !transfer_complete

func should_hand_item():
		# This should be checked by the main update_animations function
		return active && is_player_in_range() && transfer_in_progress && !transfer_complete

func is_transferring():
		return active && transfer_in_progress

func start():
		active = true
		item_transferred = false
		transfer_in_progress = false
		transfer_complete = false
		start_time = Time.get_ticks_msec() / 1000.0  # Record start time in seconds

func stop():
		if !active:
				return  # Prevent double-stopping
				
		active = false
		transfer_in_progress = false
