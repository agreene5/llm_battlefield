# 1. Create a GPUParticles2D node in your scene
# 2. Set up the properties as follows:

extends GPUParticles2D

func _ready():
	# Basic setup
	amount = 40
	lifetime = 0.5
	explosiveness = 0.8
	local_coords = false
	
	# Create the process material
	var particle_material = ParticleProcessMaterial.new()
	process_material = particle_material
	
	# Set emission shape to point
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	
	# Set direction and spread
	particle_material.direction = Vector3(0, 0, 0)
	particle_material.spread = 180.0
	
	# Set initial velocity for sharp lines coming from center
	particle_material.initial_velocity_min = 100.0
	particle_material.initial_velocity_max = 150.0
	
	# Set color ramp for light blue to white
	var gradient = Gradient.new()
	gradient.colors = [Color(0.5, 0.8, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.0)]
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	particle_material.color_ramp = gradient_texture
	
	# Make particles thinner for sharp line effect
	particle_material.scale_min = 0.5
	particle_material.scale_max = 1.5
	particle_material.scale_curve = create_scale_curve()
	
	# For continuous looping, set emitting to true
	emitting = true
	
	# Create a simple line texture and assign it to the node
	texture = create_line_texture()

func create_scale_curve():
	var curve = Curve.new()
	curve.add_point(Vector2(0, 0.6))
	curve.add_point(Vector2(0.2, 1.0))
	curve.add_point(Vector2(1.0, 0.2))
	
	var curve_texture = CurveTexture.new()
	curve_texture.curve = curve
	return curve_texture

func create_line_texture():
	var img = Image.new()
	img.create(16, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	
	var texture = ImageTexture.new()
	texture.create_from_image(img)
	return texture
