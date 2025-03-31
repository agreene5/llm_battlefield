extends Node

#func _ready():
	#await get_tree().create_timer(30.0).timeout
	#var env_info = get_environmental_info()
	#print(env_info)

# Helper function to find the correct range in dictionary
func find_range_key(value, ranges_dict):
		for range_key in ranges_dict.keys():
				if "-" in range_key:
						var bounds = range_key.split("-")
						var lower = int(bounds[0])
						var upper = 999999 if bounds[1] == "+" else int(bounds[1])
						if value >= lower and value <= upper:
								return range_key
				elif "+" in range_key:
						var lower = int(range_key.split("+")[0])
						if value >= lower:
								return range_key
				else:
						if value == int(range_key):
								return range_key
		return null

# Helper function to calculate distance between positions
func calculate_distance(pos1, pos2):
		return pos1.distance_to(pos2)

# Helper function to find nearest entity in a group
func find_nearest_entity_distance(group_name, reference_position):
		var entities = get_tree().get_nodes_in_group(group_name)
		if entities.size() == 0:
				return 999999
		
		var min_distance = 999999
		for entity in entities:
				var distance = calculate_distance(reference_position, entity.global_position)
				min_distance = min(distance, min_distance)
		
		return min_distance

func get_environmental_info():
	# Calculate distance between player and teammate
	var player_teammate_distance = 0
	if Global_Variables.player_position and Global_Variables.teammate_position:
			player_teammate_distance = calculate_distance(Global_Variables.player_position, Global_Variables.teammate_position)
	
	# Get counts from groups
	var enemy_count = get_tree().get_nodes_in_group("Enemies").size()
	var health_box_count = get_tree().get_nodes_in_group("Health_Box").size()
	var weapon_box_count = get_tree().get_nodes_in_group("Weapon_Box").size()
	
	# Calculate distances to nearest entities
	var nearest_enemy_distance = find_nearest_entity_distance("Enemies", Global_Variables.teammate_position)
	var nearest_health_box_distance = find_nearest_entity_distance("Health_Box", Global_Variables.teammate_position)
	var nearest_weapon_box_distance = find_nearest_entity_distance("Weapon_Box", Global_Variables.teammate_position)
	
	# Round distances to integers
	player_teammate_distance = round(player_teammate_distance)
	nearest_enemy_distance = round(nearest_enemy_distance)
	nearest_health_box_distance = round(nearest_health_box_distance)
	nearest_weapon_box_distance = round(nearest_weapon_box_distance)
	
	# Get health ranges
	var teammate_health_range = find_range_key(Global_Variables.teammate_health, Global_Variables.nested_dict["botson_health"])
	var player_health_range = find_range_key(Global_Variables.player_health, Global_Variables.nested_dict["player_health"])
	if teammate_health_range == null:
		teammate_health_range = "61-100"
	if player_health_range == null:
		player_health_range = "61-100"


	# Get distance ranges
	var player_distance_range = find_range_key(player_teammate_distance, Global_Variables.nested_dict["player_distance_to_botson"])
	var enemy_amount_range = find_range_key(enemy_count, Global_Variables.nested_dict["enemy_amount"])
	var nearest_enemy_range = find_range_key(nearest_enemy_distance, Global_Variables.nested_dict["nearest_enemy"])
	var health_box_amount_range = find_range_key(health_box_count, Global_Variables.nested_dict["health_box_amount"])
	var nearest_health_box_range = find_range_key(nearest_health_box_distance, Global_Variables.nested_dict["nearest_health_box"])
	var weapon_box_amount_range = find_range_key(weapon_box_count, Global_Variables.nested_dict["weapon_box_amount"])
	var nearest_weapon_box_range = find_range_key(nearest_weapon_box_distance, Global_Variables.nested_dict["nearest_weapon_box"])
	
	if health_box_amount_range == null:
		health_box_amount_range = "0"
	if weapon_box_amount_range == null:
		weapon_box_amount_range = "0"
	
	# Determine teammate inventory state
	var teammate_inventory_key = "empty"
	if Global_Variables.teammate_item == "health":
			teammate_inventory_key = "heart"
	elif Global_Variables.teammate_item in ["basic", "uncommon", "rare", "epic", "legendary"]:
			teammate_inventory_key = "basic,uncommon,rare,epic,legendary"
	
	# Determine player inventory state
	var player_inventory_key = "empty"
	if Global_Variables.player_item == "health":
			player_inventory_key = "heart"
	elif Global_Variables.player_item in ["basic", "uncommon", "rare", "epic", "legendary"]:
			player_inventory_key = "basic,uncommon,rare,epic,legendary"
	
	# Create a list to hold info items with their priorities
	var info_items = []
	
	# Add all environmental information items with their priorities
	info_items.append({
			"text": "Your health: %d/100, # %s" % [
					Global_Variables.teammate_health,
					Global_Variables.nested_dict["botson_health"][teammate_health_range][0]
			],
			"priority": Global_Variables.nested_dict["botson_health"][teammate_health_range][1]
	})
	
	info_items.append({
			"text": "Your weapon: \"%s\", # %s" % [
					Global_Variables.teammate_weapon,
					Global_Variables.nested_dict["botson_weapon"][Global_Variables.teammate_weapon][0]
			],
			"priority": Global_Variables.nested_dict["botson_weapon"][Global_Variables.teammate_weapon][1]
	})
	
	info_items.append({
			"text": "Your inventory: \"%s\", # %s" % [
					Global_Variables.teammate_item if Global_Variables.teammate_item else "empty",
					Global_Variables.nested_dict["botson_inventory"][teammate_inventory_key][0]
			],
			"priority": Global_Variables.nested_dict["botson_inventory"][teammate_inventory_key][1]
	})
	
	info_items.append({
			"text": "Player health: %d/100, # %s" % [
					Global_Variables.player_health,
					Global_Variables.nested_dict["player_health"][player_health_range][0]
			],
			"priority": Global_Variables.nested_dict["player_health"][player_health_range][1]
	})
	
	info_items.append({
			"text": "Player weapon: \"%s\", # %s" % [
					Global_Variables.player_weapon,
					Global_Variables.nested_dict["player_weapon"][Global_Variables.player_weapon][0]
			],
			"priority": Global_Variables.nested_dict["player_weapon"][Global_Variables.player_weapon][1]
	})
	
	info_items.append({
			"text": "Player inventory: \"%s\", # %s" % [
					Global_Variables.player_item if Global_Variables.player_item else "empty",
					Global_Variables.nested_dict["player_inventory"][player_inventory_key][0]
			],
			"priority": Global_Variables.nested_dict["player_inventory"][player_inventory_key][1]
	})
	
	info_items.append({
			"text": "Player_Distance_To_You: %d meters, # %s" % [
					player_teammate_distance,
					Global_Variables.nested_dict["player_distance_to_botson"][player_distance_range][0]
			],
			"priority": Global_Variables.nested_dict["player_distance_to_botson"][player_distance_range][1]
	})
	
	info_items.append({
			"text": "Enemy amount: %d, # %s" % [
					enemy_count,
					Global_Variables.nested_dict["enemy_amount"][enemy_amount_range][0]
			],
			"priority": Global_Variables.nested_dict["enemy_amount"][enemy_amount_range][1]
	})
	
	info_items.append({
			"text": "Nearest_Enemy: %d meter, # %s" % [
					nearest_enemy_distance,
					Global_Variables.nested_dict["nearest_enemy"][nearest_enemy_range][0]
			],
			"priority": Global_Variables.nested_dict["nearest_enemy"][nearest_enemy_range][1]
	})
	
	info_items.append({
			"text": "Health_Box amount: %d, # %s" % [
					health_box_count,
					Global_Variables.nested_dict["health_box_amount"][health_box_amount_range][0]
			],
			"priority": Global_Variables.nested_dict["health_box_amount"][health_box_amount_range][1]
	})
	
	info_items.append({
			"text": "Nearest_Health_Box: %d meters, # %s" % [
					nearest_health_box_distance,
					Global_Variables.nested_dict["nearest_health_box"][nearest_health_box_range][0]
			],
			"priority": Global_Variables.nested_dict["nearest_health_box"][nearest_health_box_range][1]
	})
	
	info_items.append({
			"text": "Weapon_Box amount: %d, # %s" % [
					weapon_box_count,
					Global_Variables.nested_dict["weapon_box_amount"][weapon_box_amount_range][0]
			],
			"priority": Global_Variables.nested_dict["weapon_box_amount"][weapon_box_amount_range][1]
	})
	
	info_items.append({
			"text": "Nearest_Weapon_Box: %d meters, # %s" % [
					nearest_weapon_box_distance,
					Global_Variables.nested_dict["nearest_weapon_box"][nearest_weapon_box_range][0]
			],
			"priority": Global_Variables.nested_dict["nearest_weapon_box"][nearest_weapon_box_range][1]
	})
	
	# Sort items by priority (HIGH at top, LOW at bottom)
	info_items.sort_custom(func(a, b): 
		# Map priority constants to numeric values
		var get_priority_value = func(priority):
			if priority == Global_Variables.HIGH:
				return 0
			elif priority == Global_Variables.MED:
				return 1
			else:  # LOW
				return 2
		
		# Compare using our mapped values (lower value = higher priority)
		return get_priority_value.call(a["priority"]) < get_priority_value.call(b["priority"])
	)
	
	# Filter items to include all HIGH priority items and up to 2 MEDIUM priority items
	var filtered_items = []
	var medium_count = 0
	
	for item in info_items:
		if item["priority"] == Global_Variables.HIGH:
			filtered_items.append(item)
		elif item["priority"] == Global_Variables.MED and medium_count < 2:
			filtered_items.append(item)
			medium_count += 1
	
	# Build the final string from filtered items
	var environmental_info = "Environmental info:\n"
	for item in filtered_items:
		environmental_info += item["text"] + "\n"
	
	# Remove the trailing newline if needed
	if environmental_info.ends_with("\n"):
		environmental_info = environmental_info.substr(0, environmental_info.length() - 1)
	
	return environmental_info
