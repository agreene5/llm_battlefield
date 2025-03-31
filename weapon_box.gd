extends MeshInstance3D

var player_in_range = false
var teammate_in_range = false
var lifetime_timer = 0.0

# Define weapon types and their weights
var weapon_options = {
		"uncommon": 0.60,
		"rare": 0.25,
		"epic": 0.1,
		"legendary": 0.05
}

# Define weapon colors
var weapon_colors = {
		"basic": Color.SADDLE_BROWN,
		"uncommon": Color.GREEN,
		"rare": Color.CYAN,
		"epic": Color.PURPLE,
		"legendary": Color.WHITE
}

# Randomly chosen weapon
var weapon_inside = ""

func _ready():
		# Set random weapon on initialization
		weapon_inside = select_random_weapon()
		
		# Set the color based on weapon type
		set_weapon_color()

# Function to select a random weapon based on weights
func select_random_weapon():
		var total_weight = 0.0
		for weight in weapon_options.values():
				total_weight += weight
		
		var random_value = randf() * total_weight
		var current_sum = 0.0
		
		for weapon_type in weapon_options:
				current_sum += weapon_options[weapon_type]
				if random_value <= current_sum:
						return weapon_type
		
		# Fallback (should never reach here)
		return "basic"

# Function to set color based on weapon type
func set_weapon_color():
		if weapon_inside in weapon_colors:
				# Get the specific mesh we want to tint
				var geometry = get_node("geometry_0")
				if geometry:
						# Get the existing material
						var material = geometry.get_active_material(0)
						
						# Create a new instance of the material to avoid modifying the original resource
						var new_material = material.duplicate()
						
						# Apply tint to the existing material
						if new_material is StandardMaterial3D:
								# Get the tint color
								var tint_color = weapon_colors[weapon_inside]
								
								# Simply apply the tint color (this will tint the texture if one exists)
								new_material.albedo_color = tint_color
								
								# Apply the modified material
								geometry.set_surface_override_material(0, new_material)

func _process(delta):
		# Update lifetime timer
		lifetime_timer += delta
		
		# Check if lifetime exceeded 90 seconds
		if lifetime_timer >= 90.0:
				queue_free()
				return
				
		if player_in_range:
				if Input.is_action_just_pressed("r"):
						#print("TOOK WEAPON!")
						Global_Variables.player_weapon = weapon_inside
						#print("new weapon: ", Global_Variables.player_weapon)
						queue_free()
				if Input.is_action_just_pressed("e"):
						Global_Variables.set_player_item(weapon_inside)
						#print("Picked Up Weapon!!")
						queue_free()
		if teammate_in_range:
				if Global_Variables.equip_item:
						Global_Variables.teammate_weapon = weapon_inside
						#print("TEAMMATE EQUIPED SWORD!!!")
						queue_free()
				elif Global_Variables.pickup_item:
						Global_Variables.set_teammate_item(weapon_inside)
						#print("TEAMMATE PICKED UP SWORD!!!")
						queue_free()

func _on_weapon_box_area_area_entered(area):
		if area.name == "Player_Area":
				Global_Variables.near_box = true
				player_in_range = true
		if area.name == "TeamMate_Hitbox":
				teammate_in_range = true

func _on_weapon_box_area_area_exited(area):
		if area.name == "Player_Area":
				Global_Variables.near_box = false
				player_in_range = false
		if area.name == "TeamMate_Hitbox":
				teammate_in_range = false
