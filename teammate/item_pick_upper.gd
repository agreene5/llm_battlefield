extends Node

var active = false
var parent
var anim_tree
var state_machine
var global_var_timer = null
var pickup_delay_timer = null
var previous_node = ""
var animation_complete_timer = null

func _ready():
		parent = get_parent()
		anim_tree = parent.get_node("AnimationTree")
		state_machine = anim_tree.get("parameters/playback")
		
		# Create timer for setting global variable back to false
		global_var_timer = Timer.new()
		global_var_timer.one_shot = true
		global_var_timer.wait_time = 0.1
		global_var_timer.timeout.connect(_on_global_var_timer_timeout)
		add_child(global_var_timer)
		
		# Create timer for pickup delay
		pickup_delay_timer = Timer.new()
		pickup_delay_timer.one_shot = true
		pickup_delay_timer.wait_time = 3.0  # Keep your original 3-second delay
		pickup_delay_timer.timeout.connect(_on_pickup_delay_timeout)
		add_child(pickup_delay_timer)
		
		# Create timer to ensure animation completes properly
		animation_complete_timer = Timer.new()
		animation_complete_timer.one_shot = true
		animation_complete_timer.wait_time = 1.0
		animation_complete_timer.timeout.connect(_on_animation_complete)
		add_child(animation_complete_timer)

func _process(delta):
		if not active:
				return
		
		var current_node = state_machine.get_current_node()
		
		# Check if we've transitioned from Pick_Up to another state
		if previous_node == "Pick_Up" and current_node != "Pick_Up":
				# Animation completed, go back to idle
				anim_tree.set("parameters/conditions/back_idle", true)
				anim_tree.set("parameters/conditions/pick_up", false)
				stop()
		
		previous_node = current_node

func _on_global_var_timer_timeout():
		# Reset global variable
		Global_Variables.pickup_item = false

func _on_pickup_delay_timeout():
		# After delay, now actually pick up the item
		Global_Variables.pickup_item = true
		
		# Start timer to reset global variable
		global_var_timer.start()
		
		# Start timer to ensure animation completes
		animation_complete_timer.start()

func _on_animation_complete():
		if active:
				# Backup method to ensure stop() is called if animation detection fails
				stop()

func start():
		active = true
		previous_node = state_machine.get_current_node()
		
		# Force transition to pickup animation directly
		state_machine.travel("Pick_Up")
		
		# Set animation parameters
		anim_tree.set("parameters/conditions/pick_up", true)
		anim_tree.set("parameters/conditions/idle", false)
		anim_tree.set("parameters/conditions/run", false)
		anim_tree.set("parameters/conditions/attack", false)
		
		# Start the pickup delay timer
		pickup_delay_timer.start()

func stop():
		active = false
		
		# Reset ALL animation conditions to ensure we're not stuck
		anim_tree.set("parameters/conditions/pick_up", false)
		anim_tree.set("parameters/conditions/back_idle", false)
		anim_tree.set("parameters/conditions/idle", true)
		anim_tree.set("parameters/conditions/run", false)
		anim_tree.set("parameters/conditions/attack", false)
		
		# Force transition to idle state
		state_machine.travel("Sword_Idle")
		
		Global_Variables.pass_enviroment_to_teammate()
		get_parent().default_behavior_start()
