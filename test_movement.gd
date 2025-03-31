extends CharacterBody3D

const SPEED = 4.0

@onready var nav_agent = $NavigationAgent3D

func _physics_process(delta):
	# Get the current player position from Global_Variables
	var player_position = Global_Variables.player_position
	
	# Set navigation target to player position
	nav_agent.set_target_position(player_position)
	
	# Get next navigation point
	var next_nav_point = nav_agent.get_next_path_position()
	
	# Calculate direction to move
	var direction = (next_nav_point - global_position).normalized()
	
	# Set velocity with speed
	velocity = direction * SPEED
	
	# Move the character
	move_and_slide()
