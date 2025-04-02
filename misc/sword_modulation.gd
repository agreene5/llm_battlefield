extends MeshInstance3D

# Parameter to determine which weapon to track
@export var sword_user: String = "player"  # Can be "player" or "teammate"

# Timer for color updates
var update_timer = 0
const UPDATE_INTERVAL = 0.5  # Check every 0.5 seconds

# Store the last weapon type to avoid unnecessary updates
var last_weapon_type = null

func _ready():
	# Initial color update
	update_color()

func _process(delta):
	# Increment timer
	update_timer += delta
	
	# Check if it's time to update
	if update_timer >= UPDATE_INTERVAL:
		update_timer = 0  # Reset timer
		
		# Get the current weapon based on sword_user
		var current_weapon = Global_Variables.player_weapon if sword_user == "player" else Global_Variables.teammate_weapon
		
		# Only update if the weapon has changed
		if last_weapon_type != current_weapon:
			update_color()

func update_color():
	# Get the weapon type based on sword_user
	var weapon_type
	if sword_user == "player":
		weapon_type = Global_Variables.player_weapon
	else:  # "teammate"
		weapon_type = Global_Variables.teammate_weapon
	
	last_weapon_type = weapon_type
	
	# Define the weapon colors
	var weapon_types = { 
		"basic": Color.SADDLE_BROWN, 
		"uncommon": Color.GREEN,
		"rare": Color.CYAN,
		"epic": Color.PURPLE,
		"legendary": Color.WHITE,
	}
	
	# Get the color for the current weapon type
	var color = weapon_types.get(weapon_type, Color.WHITE)
	
	# Update the existing material
	if get_surface_override_material(0) != null:
		var mat = get_surface_override_material(0)
		apply_color_to_material(mat, color)
	elif material_override != null:
		var mat = material_override
		apply_color_to_material(mat, color)
	else:
		var mat = mesh.surface_get_material(0)
		if mat:
			mat = mat.duplicate()
			apply_color_to_material(mat, color)
			set_surface_override_material(0, mat)

func apply_color_to_material(mat, color):
	if mat is StandardMaterial3D:
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color * 0.3  # Add emission for brightness
		mat.emission_energy = 1.5   # Control emission intensity
	elif mat is ShaderMaterial:
		if mat.get_shader().has_param("modulate"):
			mat.set_shader_param("modulate", color)
		if mat.get_shader().has_param("emission_color"):
			mat.set_shader_param("emission_color", color * 0.3)
			mat.set_shader_param("emission_energy", 1.5)
