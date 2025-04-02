extends Node

@export var health_box_scene: PackedScene = preload("res://health_box.tscn")
@export var weapon_box_scene: PackedScene = preload("res://weapon_box.tscn")
@export var nav_region: NavigationRegion3D
@export var player: Node3D
@export var min_distance: float = 20.0
@export var max_distance: float = 80.0
@export var spawn_height_offset: float = 0.5  # Height above navmesh to spawn

# Box spawn settings - initial and final values
@export_group("Spawn Settings")
@export var initial_health_box_interval: float = 30.0
@export var initial_weapon_box_interval: float = 45.0
@export var initial_max_health_boxes: int = 2
@export var initial_max_weapon_boxes: int = 2
@export var final_health_box_interval: float = 10.0
@export var final_weapon_box_interval: float = 20.0
@export var final_max_health_boxes: int = 5
@export var final_max_weapon_boxes: int = 3
@export var transition_time: float = 300.0  # Time in seconds for full transition

var rng = RandomNumberGenerator.new()
var health_box_timer: Timer
var weapon_box_timer: Timer
var game_time: float = 0.0

func _ready():
		rng.randomize()
		
		# Create timer for health box spawning
		health_box_timer = Timer.new()
		health_box_timer.wait_time = initial_health_box_interval
		health_box_timer.one_shot = false
		health_box_timer.timeout.connect(_on_health_box_timer_timeout)
		add_child(health_box_timer)
		
		# Create timer for weapon box spawning
		weapon_box_timer = Timer.new()
		weapon_box_timer.wait_time = initial_weapon_box_interval
		weapon_box_timer.one_shot = false
		weapon_box_timer.timeout.connect(_on_weapon_box_timer_timeout)
		add_child(weapon_box_timer)
		
		# Start timers
		health_box_timer.start()
		weapon_box_timer.start()
		
		await get_tree().create_timer(5).timeout
		
		spawn_health_box()
		spawn_weapon_box()

func _process(delta):
		# Update game time
		game_time += delta

func _on_health_box_timer_timeout():
		spawn_health_box()
		
		# Update the timer's wait time for the next spawn
		var progress = clamp(game_time / transition_time, 0.0, 1.0)
		var new_interval = lerp(initial_health_box_interval, final_health_box_interval, progress)
		health_box_timer.wait_time = new_interval

func _on_weapon_box_timer_timeout():
		spawn_weapon_box()
		
		# Update the timer's wait time for the next spawn
		var progress = clamp(game_time / transition_time, 0.0, 1.0)
		var new_interval = lerp(initial_weapon_box_interval, final_weapon_box_interval, progress)
		weapon_box_timer.wait_time = new_interval

func get_max_health_boxes():
		var progress = clamp(game_time / transition_time, 0.0, 1.0)
		return int(lerp(float(initial_max_health_boxes), float(final_max_health_boxes), progress))

func get_max_weapon_boxes():
		var progress = clamp(game_time / transition_time, 0.0, 1.0)
		return int(lerp(float(initial_max_weapon_boxes), float(final_max_weapon_boxes), progress))

func spawn_health_box():
		# Check if we already have max health boxes
		var existing_health_boxes = get_tree().get_nodes_in_group("Health_Box")
		if existing_health_boxes.size() >= get_max_health_boxes():
				return
				
		var spawn_pos = find_valid_spawn_point()
		if spawn_pos:
				var health_box_instance = health_box_scene.instantiate()
				get_parent().add_child(health_box_instance)
				health_box_instance.global_position = spawn_pos
				
				# Ensure the box is in the correct group
				if not health_box_instance.is_in_group("Health_Box"):
						health_box_instance.add_to_group("Health_Box")

func spawn_weapon_box():
		# Check if we already have max weapon boxes
		var existing_weapon_boxes = get_tree().get_nodes_in_group("Weapon_Box")
		if existing_weapon_boxes.size() >= get_max_weapon_boxes():
				return
				
		var spawn_pos = find_valid_spawn_point()
		if spawn_pos:
				var weapon_box_instance = weapon_box_scene.instantiate()
				get_parent().add_child(weapon_box_instance)
				weapon_box_instance.global_position = spawn_pos
				
				# Ensure the box is in the correct group
				if not weapon_box_instance.is_in_group("Weapon_Box"):
						weapon_box_instance.add_to_group("Weapon_Box")

func find_valid_spawn_point():
		if !nav_region or !player:
				push_error("NavRegion or Player not set!")
				return null
		
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
						return closest_point
		
		# If we get here, we couldn't find a valid spawn point
		return null
