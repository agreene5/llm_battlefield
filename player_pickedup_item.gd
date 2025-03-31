# ItemSprite.gd
extends Sprite2D

func _ready():
	# Connect to the signal that notifies when player_item changes
	Global_Variables.player_item_changed.connect(update_sprite)
	
	# Initialize the sprite based on the current value
	update_sprite()
	
func _process(delta):
	update_sprite()

func update_sprite():
	var item = Global_Variables.player_item
	
	if item in ["basic", "uncommon", "rare", "epic", "legendary"]:
		# Set to sword texture with appropriate color modulation
		texture = load("res://Assets/Temp_Assets/Sword_Icon.png")
		modulate = Global_Variables.weapon_types[item][1]
		visible = true
	elif item == "health":
		# Set to heart texture with default modulation
		texture = load("res://Assets/Temp_Assets/Heart_Icon.png")
		modulate = Color(1, 1, 1, 1)  # Default modulation (white)
		visible = true
	else:
		# If null or anything else, make it invisible
		visible = false
