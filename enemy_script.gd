extends CharacterBody3D

@export var SPEED = 2.5
@export var ATTACK_RANGE = 2.0
const ATTACK_ANIMATION_LENGTH = 2.6667
const DAMAGE_POINT_TIME = 1.2
const TARGET_SWITCH_COOLDOWN = 3.0
const PRIORITY_RANGE = 3.0
const MAX_ROTATION_DEGREES = 10.0  # Maximum rotation in degrees for X and Z axes

var state_machine
var player_in_attack_area = false
var teammate_in_attack_area = false
var attack_timer = 0.0
var damage_dealt = false
var target_switch_timer = 0.0
var current_target = "Player"  # Start targeting player by default

@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree
@onready var animation_player = $AnimationPlayer
@onready var audio_player = $AudioStreamPlayer2D
@export var enemy_health = 100
								
func _ready():
	state_machine = anim_tree.get("parameters/playback")
	audio_player = $AudioStreamPlayer2D
								
func _process(delta):
	velocity = Vector3.ZERO
	
	# Update target switch cooldown
	if target_switch_timer > 0:
		target_switch_timer -= delta
	
	# Determine current target
	update_current_target()
	
	match state_machine.get_current_node():
		"Zombie Run":
			var target_position = get_target_position()
			nav_agent.set_target_position(target_position)
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
			
			# Look at direction but with rotation constraint
			look_at_with_constraint(Vector3(global_position.x + velocity.x, global_position.y, global_position.z + velocity.z))
			
			# Reset attack state when not attacking
			if damage_dealt:  # Only print when state changes
				print("Exiting attack state, resetting")
			attack_timer = 0.0
			damage_dealt = false
		"Attack":
			# Look at target with rotation constraint
			look_at_with_constraint(get_target_position() + Vector3(0, -1.3, 0))
			
			# Track time in attack animation
			var previous_timer = attack_timer
			attack_timer += delta
			
			# Only print when crossing the damage threshold
			if previous_timer < DAMAGE_POINT_TIME && attack_timer >= DAMAGE_POINT_TIME:
				print("Attack reached damage point: ", attack_timer, ", Target in area: ", target_in_attack_area())
			
			# Check if we're at the damage point and haven't dealt damage yet
			if attack_timer >= DAMAGE_POINT_TIME and !damage_dealt:
				if target_in_attack_area():
					print("Attempting to emit attack signal")
					# Emit the appropriate signal through Global_Variables
					if current_target == "Player" && Global_Variables.has_signal("enemy_attacked_player"):
						Global_Variables.emit_signal("enemy_attacked_player", name)
						print("Player attack signal emitted successfully from " + name)
						damage_dealt = true
					elif current_target == "Teammate" && Global_Variables.has_signal("enemy_attacked_teammate"):
						Global_Variables.emit_signal("enemy_attacked_teammate", name)
						print("Teammate attack signal emitted successfully from " + name)
						damage_dealt = true
					else:
						print("ERROR: Required attack signal doesn't exist in Global_Variables")
			
			# Reset for next attack cycle
			if previous_timer < ATTACK_ANIMATION_LENGTH && attack_timer >= ATTACK_ANIMATION_LENGTH:
				print("Attack animation complete, resetting timer")
				attack_timer = 0.0
				damage_dealt = false
				
		"Stand Up":
			pass
	
	anim_tree.set("parameters/conditions/attack", target_in_range())
	anim_tree.set("parameters/conditions/run", !target_in_range())
	
	move_and_slide()

# Function to play a random hurt sound effect
func play_random_hurt_sound():
	# Randomly select a sound from the array
	var random_index = randi() % Global_Variables.zombie_hurt_sfx.size()
	var selected_sfx = Global_Variables.zombie_hurt_sfx[random_index]
	
	# Load and play the selected sound
	audio_player.stream = load(selected_sfx)
	audio_player.play()

# Function to look at a target while constraining X and Z rotation
func look_at_with_constraint(target_pos):
	# First, do a normal look_at to get the ideal rotation
	look_at(target_pos, Vector3.UP)
	
	# Then, constrain the X and Z rotations
	var current_rotation = rotation_degrees
	var max_angle = MAX_ROTATION_DEGREES
	
	# Clamp X and Z rotations
	rotation_degrees.x = clamp(rotation_degrees.x, -max_angle, max_angle)
	rotation_degrees.z = clamp(rotation_degrees.z, -max_angle, max_angle)

func update_current_target():
	var player_distance = global_position.distance_to(Global_Variables.player_position)
	var teammate_distance = INF
	
	# Get teammate position if available
	var teammates = get_tree().get_nodes_in_group("Teammate")
	if teammates.size() > 0:
		var closest_teammate = teammates[0]
		for teammate in teammates:
			var dist = global_position.distance_to(teammate.global_position)
			if dist < teammate_distance:
				teammate_distance = dist
				closest_teammate = teammate
		teammate_distance = global_position.distance_to(closest_teammate.global_position)
	
	# Priority check: if both targets are within priority range, always choose player
	if player_distance < PRIORITY_RANGE && teammate_distance < PRIORITY_RANGE:
		current_target = "Player"
		return
	
	# Only switch target if cooldown is complete
	if target_switch_timer <= 0:
		var new_target = current_target
		
		# Determine closest target
		if teammate_distance < player_distance && teammate_distance != INF:
			new_target = "Teammate"
		else:
			new_target = "Player"
		
		# If target changed, apply cooldown
		if new_target != current_target:
			current_target = new_target
			target_switch_timer = TARGET_SWITCH_COOLDOWN
			print("Target switched to: " + current_target)

func get_target_position():
	if current_target == "Player":
		return Global_Variables.player_position
	else:  # Teammate
		return Global_Variables.teammate_position

func target_in_range():
	if current_target == "Player":
		return global_position.distance_to(Global_Variables.player_position) < ATTACK_RANGE
	else:  # Teammate
		return global_position.distance_to(Global_Variables.teammate_position) < ATTACK_RANGE

func target_in_attack_area():
	if current_target == "Player":
		return player_in_attack_area
	else:  # Teammate
		return teammate_in_attack_area

func _on_enemy_hitbox_area_entered(area):
	# ENEMY MESH $Armature/Skeleton3D/Enemy_Mesh
	if area.name == "Hitbox":
		enemy_health -= Global_Variables.weapon_types[Global_Variables.player_weapon][0]
		$SubViewport/HealthBar3D.value -= Global_Variables.weapon_types[Global_Variables.player_weapon][0]
		play_random_hurt_sound()  # Play random hurt sound when hit by player
		_flash_red()
		if enemy_health <= 0:
			print("Dead")
			Global_Variables.enemies_killed += 1
			if Global_Variables.enemies_killed > Global_Variables.high_score:
				Global_Variables.high_score = Global_Variables.enemies_killed
			queue_free()
		#print("Player Hit! Enemy Health: ", enemy_health)
	elif area.name == "TeamMate_Sword_Hitbox":
		enemy_health -= Global_Variables.weapon_types[Global_Variables.teammate_weapon][0]
		$SubViewport/HealthBar3D.value -= Global_Variables.weapon_types[Global_Variables.teammate_weapon][0]
		play_random_hurt_sound()  # Play random hurt sound when hit by teammate
		_flash_red()
		if enemy_health <= 0:
			print("Dead")
			Global_Variables.enemies_killed += 1
			if Global_Variables.enemies_killed > Global_Variables.high_score:
				Global_Variables.high_score = Global_Variables.enemies_killed
			queue_free()
		#print("TeamMate Hit! Enemy Health: ", enemy_health)

var flash_tween = null
var original_materials = []
var is_flashing = false

func _flash_red():
	var mesh = $Armature/Skeleton3D/Enemy_Mesh
	
	# Cancel any existing flash
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	
	# Create a new StandardMaterial3D for the flash effect
	var flash_material = StandardMaterial3D.new()
	flash_material.albedo_color = Color(1, 0, 0, 1)
	flash_material.emission_enabled = true
	flash_material.emission = Color(1, 0, 0, 1)
	flash_material.emission_energy = 2.0
	
	# Store the original materials only if we're not already flashing
	if not is_flashing:
		is_flashing = true
		original_materials = []
		for i in range(mesh.get_surface_override_material_count()):
			original_materials.append(mesh.get_surface_override_material(i))
	
	# Apply the flash material to all surfaces
	for i in range(mesh.get_surface_override_material_count()):
		mesh.set_surface_override_material(i, flash_material)
	
	# Revert after a delay
	flash_tween = create_tween()
	flash_tween.tween_callback(func():
		for i in range(mesh.get_surface_override_material_count()):
			if i < original_materials.size():
				mesh.set_surface_override_material(i, original_materials[i])
		is_flashing = false
	).set_delay(0.15)

# Track when player enters/exits the attack area
func _on_enemy_attackbox_area_entered(area):
	if area.name == "Player_Area":
		player_in_attack_area = true
		#print("Player entered attack area")
	elif area.name == "TeamMate_Hitbox":
		teammate_in_attack_area = true
		#print("Teammate entered attack area")

func _on_enemy_attackbox_area_exited(area):
	if area.name == "Player_Area":
		player_in_attack_area = false
		#print("Player exited attack area")
	elif area.name == "TeamMate_Hitbox":
		teammate_in_attack_area = false
		#print("Teammate exited attack area")
