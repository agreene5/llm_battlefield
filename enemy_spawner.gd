extends Node

# Preload the enemy scenes
var enemy_scenes = {
		"enemy": preload("res://enemy.tscn"),
		"enemy_1": preload("res://enemy_3.tscn"),  # Swapped these two
		"enemy_2": preload("res://enemy_2.tscn")   # Swapped these two
}

# Map enemy type to descriptive base name
var enemy_base_names = {
		"enemy": "first_enemy",
		"enemy_2": "second_enemy",
		"enemy_1": "third_enemy"
}

# Track count of each enemy type for naming
var enemy_counts = {
		"enemy": 0,
		"enemy_1": 0,
		"enemy_2": 0
}

@export var nav_region: NavigationRegion3D
@export var player: Node3D
@export var min_distance: float = 20.0
@export var max_distance: float = 80.0
@export var spawn_height_offset: float = 1.0  # Height above navmesh to spawn
@export var max_enemies: int = 15  # Maximum number of enemies allowed at once

# Spawn configuration: [enemy_type, start_time, initial_interval, final_interval]
var spawn_times = [
		["enemy", 0, 20, 5],
		["enemy_1", 80, 30, 5], # 80
		["enemy_2", 160, 45, 8] # 160
]

var enemies_spawned: int = 0
var active_enemies: int = 0
var rng = RandomNumberGenerator.new()
var game_start_time: float
var timers = {}
var active_enemy_nodes = []  # Keep track of active enemy nodes

func _ready():
		rng.randomize()
		game_start_time = Time.get_ticks_msec() / 1000.0
		
		# Set up timers and initial spawn for each enemy type
		for config in spawn_times:
				var enemy_type = config[0]
				var start_time = config[1]
				
				# Create a timer for this enemy type
				var timer = Timer.new()
				timer.name = "Timer_" + enemy_type
				timer.one_shot = true
				timer.timeout.connect(func(): _on_enemy_spawn_timer_timeout(enemy_type))
				add_child(timer)
				timers[enemy_type] = timer
				
				# If this is the enemy that spawns immediately, handle it separately
				if start_time == 0:
						# Schedule first spawn after 1 second
						await get_tree().create_timer(1.0).timeout
						spawn_enemy(enemy_type)
						
						# Start the timer for the next spawn
						timer.wait_time = config[2]  # Initial interval
						timer.start()
				else:
						# Schedule a timer to start spawning at the appropriate time
						var start_timer = Timer.new()
						start_timer.one_shot = true
						start_timer.wait_time = float(start_time)
						start_timer.timeout.connect(func(): _start_enemy_spawning(enemy_type))
						add_child(start_timer)
						start_timer.start()

func _process(delta):
		# Clean up the list of active enemies by checking if they still exist
		var i = 0
		while i < active_enemy_nodes.size():
				if !is_instance_valid(active_enemy_nodes[i]) or active_enemy_nodes[i].is_queued_for_deletion():
						active_enemy_nodes.remove_at(i)
						active_enemies -= 1
				else:
						i += 1

func _start_enemy_spawning(enemy_type):
		# Find the config for this enemy type
		for config in spawn_times:
				if config[0] == enemy_type:
						# Spawn immediately (if under enemy cap)
						spawn_enemy(enemy_type)
						
						# Start the timer for the next spawn
						var timer = timers[enemy_type]
						
						# Determine which interval to use
						var current_time = Time.get_ticks_msec() / 1000.0
						var elapsed_time = current_time - game_start_time
						var interval = config[2]  # Default to initial interval
						
						if elapsed_time >= 500:
								interval = config[3]  # Use final interval
						
						timer.wait_time = interval
						timer.start()
						break

func _on_enemy_spawn_timer_timeout(enemy_type):
		# Spawn the specific enemy
		spawn_enemy(enemy_type)
		
		# Find the config for this enemy type
		for config in spawn_times:
				if config[0] == enemy_type:
						var timer = timers[enemy_type]
						var current_time = Time.get_ticks_msec() / 1000.0
						var elapsed_time = current_time - game_start_time
						
						# Default to initial interval
						var interval = config[2]
						
						# Use final interval if past 300 seconds overall game time
						if elapsed_time >= 500:
								interval = config[3]
						
						timer.wait_time = interval
						timer.start()
						break

func spawn_enemy(enemy_type):
		# Check if we've hit the enemy cap
		if active_enemies >= max_enemies:
				print("Enemy cap reached, skipping spawn")
				return
				
		if !nav_region or !player:
				push_error("NavRegion or Player not set!")
				return
		
		var enemy_scene_to_spawn = enemy_scenes[enemy_type]
		var nav_mesh = nav_region.navigation_mesh
		var player_pos = player.global_position
		
		# Try up to 10 times to find a valid spawn point
		for _attempt in range(10):
				# Generate random angle
				var angle = rng.randf_range(0, TAU)
				# Generate random distance between min and max
				var distance = rng.randf_range(min_distance, max_distance)
				
				# Calculate potential spawn position (on a circle around player)
				var offset = Vector3(cos(angle) * distance, 0, sin(angle) * distance)
				var potential_pos = player_pos + offset
				
				# Project point onto navigation mesh
				var closest_point = NavigationServer3D.map_get_closest_point(
								nav_region.get_navigation_map(), potential_pos)
				
				# Check if the point is valid (not too far from our intended position)
				if potential_pos.distance_to(closest_point) < 2.0:
								# Add a small height offset to prevent spawning inside the ground
								closest_point.y += spawn_height_offset
								
								# Spawn the enemy
								var enemy_instance = enemy_scene_to_spawn.instantiate()
								
								# Increment the count for this enemy type
								enemy_counts[enemy_type] += 1
								
								# Use the descriptive base name and add sequential numbering
								var base_name = enemy_base_names[enemy_type]
								var enemy_number = enemy_counts[enemy_type]
								
								# Set the name before adding to scene
								enemy_instance.name = base_name + "_" + str(enemy_number)
								
								get_parent().add_child(enemy_instance)
								enemy_instance.global_position = closest_point
								
								# Track the new enemy
								active_enemy_nodes.append(enemy_instance)
								active_enemies += 1
								enemies_spawned += 1
								
								# Connect to the enemy's tree_exiting signal if possible
								if enemy_instance.has_signal("tree_exiting"):
										enemy_instance.tree_exiting.connect(func(): _on_enemy_died(enemy_instance))
								
								return

func _on_enemy_died(enemy):
		if enemy in active_enemy_nodes:
				active_enemy_nodes.erase(enemy)
				active_enemies -= 1
