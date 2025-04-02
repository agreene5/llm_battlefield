extends Node

const SPEED = 4.0
const ATTACK_RANGE = 2

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
		
		# Check if 30 seconds have passed
		if timer >= 30.0 and timer < 30.0 + delta:
				Global_Variables.pass_enviroment_to_teammate()
				get_parent().default_behavior_start()

		if not active:
				return
						
		process_movement(delta)

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

func process_movement(delta):
		parent.velocity = Vector3.ZERO
		
		# Find the nearest enemy
		find_nearest_enemy()
		
		if nearest_enemy == null:
				return
		
		if should_attack():
				# When attacking, ensure velocity is zero and face the enemy
				parent.velocity = Vector3.ZERO
				parent.look_at(nearest_enemy.global_position, Vector3.UP)
				# Add this line to trigger the attack animation
				parent.trigger_attack_animation()
		else:
				nav_agent.set_target_position(nearest_enemy.global_position)
				var next_nav_point = nav_agent.get_next_path_position()
				parent.velocity = (next_nav_point - parent.global_transform.origin).normalized() * SPEED
				parent.look_at(Vector3(parent.global_position.x + parent.velocity.x, parent.global_position.y, parent.global_position.z + parent.velocity.z), Vector3.UP)
				

func reset_timer(info):
		# Reset the timer to zero when environment is updated
		# The 'info' parameter receives the data from the signal
		timer = 0.0

func should_attack():
		return has_target() && is_target_in_range()

func should_run():
		return has_target() && !is_target_in_range()

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

func start():
		active = true

func stop():
		active = false
