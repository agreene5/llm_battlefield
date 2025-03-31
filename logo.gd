extends Node2D

@export var rotation_speed: float = 3.0  # Complete cycle in 3 seconds
@export var rotation_range: float = 5.0  # Rotation range in degrees

var initial_rotation: float = 0.0
var last_angle: float = 0.0

func _ready():
	initial_rotation = rotation_degrees
	last_angle = 0.0

func _process(delta):
	# Calculate the current rotation based on time
	var time = Time.get_ticks_msec() / 1000.0  # Convert to seconds
	var angle = rotation_range * sin(time * TAU / rotation_speed)
	
	# Calculate the difference from the last frame
	var angle_diff = angle - last_angle
	
	# Apply the difference to the current rotation
	rotation_degrees += angle_diff
	
	# Store the current angle for the next frame
	last_angle = angle
