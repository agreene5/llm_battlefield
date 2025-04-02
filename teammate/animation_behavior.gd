# AnimationBehavior.gd
extends Node

var active = false
var parent
var anim_tree
var state_machine
var current_animation = ""
var timer = null
var available_animations = ["bashful", "chicken_dance", "excited", "happy", "praying", "sad", "surprised"]

func _ready():
		parent = get_parent()
		anim_tree = parent.get_node("AnimationTree")
		state_machine = anim_tree.get("parameters/playback")
		
		# Create a timer for animation duration
		timer = Timer.new()
		timer.one_shot = true
		timer.wait_time = 10.0
		timer.timeout.connect(_on_timer_timeout)
		add_child(timer)

func _process(delta):
		if not active:
				return
		
		# Force velocity to zero during special animations
		parent.velocity = Vector3.ZERO
		
		# Keep enforcing our animation conditions every frame
		if current_animation != "":
				enforce_animation_conditions()

func enforce_animation_conditions():
		# This function will be called every frame to override any changes from other systems
		
		# Ensure run is FALSE and idle is TRUE
		anim_tree.set("parameters/conditions/run", false)
		anim_tree.set("parameters/conditions/idle", true)
		
		# Ensure our specific animation condition is TRUE
		if current_animation != "":
				anim_tree.set("parameters/conditions/" + current_animation, true)

func start(animation_name = ""):
		if not anim_tree:
				push_error("AnimationTree not found")
				return
		
		animation_name = animation_name.to_lower()
		
		if animation_name not in available_animations:
				push_error("Animation not found: " + animation_name)
				return
				
		active = true
		current_animation = animation_name
		
		# Tell parent to disable other animation updates
		if parent.has_method("disable_animation_updates"):
				parent.disable_animation_updates()
		
		# Reset all conditions first
		reset_animation_conditions()
		
		# Force idle state first
		state_machine.travel("Sword_Idle")
		
		# Set idle to true and run to false
		anim_tree.set("parameters/conditions/idle", true)
		anim_tree.set("parameters/conditions/run", false)
		
		# Set the requested animation condition
		anim_tree.set("parameters/conditions/" + animation_name, true)
		
		
		# Start the 10-second timer
		timer.start()

func stop():
		if !active:
				return
				
		active = false
		current_animation = ""
		
		if timer and timer.is_inside_tree():
				timer.stop()

func reset_animation_conditions():
		# Reset all animation conditions to false
		for anim in available_animations:
				anim_tree.set("parameters/conditions/" + anim, false)
		
		# Reset standard conditions too
		anim_tree.set("parameters/conditions/run", false)
		anim_tree.set("parameters/conditions/attack", false)
		anim_tree.set("parameters/conditions/hand_item", false)
		anim_tree.set("parameters/conditions/pick_up", false)
		
		# Don't reset idle yet - we'll set it to true after
		anim_tree.set("parameters/conditions/back_idle", false)

func _on_timer_timeout():
		stop()
		
		# Reset all conditions first
		reset_animation_conditions()
		
		# Set idle and back_idle to true to return to idle state
		anim_tree.set("parameters/conditions/idle", true)
		anim_tree.set("parameters/conditions/back_idle", true)
		
		# Schedule to turn off back_idle after a short delay to allow the transition
		var idle_reset_timer = Timer.new()
		add_child(idle_reset_timer)
		idle_reset_timer.wait_time = 0.2
		idle_reset_timer.one_shot = true
		idle_reset_timer.timeout.connect(func():
				anim_tree.set("parameters/conditions/back_idle", false)
				idle_reset_timer.queue_free()
				
				# Re-enable animation updates on parent
				if parent.has_method("enable_animation_updates"):
						parent.enable_animation_updates()
						
				# Return to default behavior
				get_parent().default_behavior_start()
		)
		idle_reset_timer.start()
