extends Label

func _physics_process(delta):
		text = "Health: " + str(Global_Variables.player_health)
		
		# Change text color based on health value
		if Global_Variables.player_health <= 30:
				add_theme_color_override("font_color", Color(1, 0, 0))  # Red
		elif Global_Variables.player_health <= 69:
				add_theme_color_override("font_color", Color(1, 0.5, 0))  # Orange
		else:
				add_theme_color_override("font_color", Color(0, 1, 0))  # Green
