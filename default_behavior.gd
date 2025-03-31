# DefaultBehavior.gd
extends Node

const SPEED = 4.0
const ACTION_RANGE = 5.0  # Range for both dodge and attack
const ATTACK_RANGE = 2.0  # Range for actual attack (when close enough)

var active = false
var parent
var nav_agent
var nearest_enemy = null
var enemies = []
var timer = 0.0  # Timer variable to track elapsed time

func _ready():
		Global_Variables.environment_updated.connect(reset_timer)
		parent = get_parent()
		nav_agent = parent.get_node("NavigationAgent3D")

func _process(delta):
		# Update timer regardless of active state
		timer += delta
		
		# Check if 20 seconds have passed
		if timer >= 20.0 and timer < 20.0 + delta:
				Global_Variables.pass_enviroment_to_teammate()
				get_parent().default_behavior_start()

		if not active:
				return

		process_behavior(delta)

func reset_timer(info):
		# Reset the timer to zero when environment is updated
		# The 'info' parameter receives the data from the signal
		timer = 0.0

func find_nearest_enemy():
		var shortest_distance = INF
		nearest_enemy = null

		# Get all enemies in the scene
		enemies = parent.get_tree().get_nodes_in_group("Enemies")

		for enemy in enemies:
				var distance = parent.global_position.distance_to(enemy.global_position)
				if distance < shortest_distance:
						shortest_distance = distance
						nearest_enemy = enemy

		return nearest_enemy

func process_behavior(delta):
		parent.velocity = Vector3.ZERO

		# Find the nearest enemy
		find_nearest_enemy()

		if nearest_enemy == null:
				return

		var distance_to_enemy = parent.global_position.distance_to(nearest_enemy.global_position)
		
		# Check teammate health to determine behavior
		if Global_Variables.teammate_health < 50:
				# Dodge behavior - move away from enemies if within range
				if distance_to_enemy < ACTION_RANGE:
						dodge_enemy()
		else:
				# Attack behavior - move toward and attack enemies if within range
				if distance_to_enemy < ACTION_RANGE:
						if distance_to_enemy < ATTACK_RANGE:
								attack_enemy()
						else:
								move_to_enemy()

func dodge_enemy():
		if nearest_enemy == null:
				return
				
		# Calculate direction away from enemy
		var direction_to_enemy = parent.global_position - nearest_enemy.global_position
		direction_to_enemy = direction_to_enemy.normalized()
		
		# Set a target position away from the enemy
		var dodge_target = parent.global_position + direction_to_enemy * 10.0
		
		# Use navigation to find path away from enemy
		nav_agent.set_target_position(dodge_target)
		var next_nav_point = nav_agent.get_next_path_position()
		
		# Move away from enemy
		parent.velocity = (next_nav_point - parent.global_transform.origin).normalized() * SPEED
		
		# Face the direction we're moving
		parent.look_at(Vector3(parent.global_position.x + parent.velocity.x, 
												  parent.global_position.y, 
												  parent.global_position.z + parent.velocity.z), Vector3.UP)

func move_to_enemy():
		if nearest_enemy == null:
				return
				
		# Use navigation to find path to enemy
		nav_agent.set_target_position(nearest_enemy.global_position)
		var next_nav_point = nav_agent.get_next_path_position()
		
		# Move toward enemy
		parent.velocity = (next_nav_point - parent.global_transform.origin).normalized() * SPEED
		
		# Face the direction we're moving
		parent.look_at(Vector3(parent.global_position.x + parent.velocity.x, 
												  parent.global_position.y, 
												  parent.global_position.z + parent.velocity.z), Vector3.UP)

func attack_enemy():
		if nearest_enemy == null:
				return
				
		# When attacking, ensure velocity is zero and face the enemy
		parent.velocity = Vector3.ZERO
		parent.look_at(nearest_enemy.global_position, Vector3.UP)
		
		# Add this line to explicitly signal attack state
		parent.trigger_attack_animation()
		
func has_target():
		return nearest_enemy != null

func get_target_position():
		if nearest_enemy:
				return nearest_enemy.global_position
		return parent.global_position

func is_target_in_range():
		if nearest_enemy:
				return parent.global_position.distance_to(nearest_enemy.global_position) < ATTACK_RANGE
		return false

func should_attack():
		return has_target() && is_target_in_range() && Global_Variables.teammate_health >= 50

func should_dodge():
		if !has_target():
				return false
		var distance = parent.global_position.distance_to(nearest_enemy.global_position)
		return distance < ACTION_RANGE && Global_Variables.teammate_health < 50

func start():
		active = true

func stop():
		active = false
