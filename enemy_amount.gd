extends Label

func _physics_process(delta):
		text = "Enemies Kills: " + str(Global_Variables.enemies_killed)
		
		# Change text color based on comparison with high score
		if Global_Variables.enemies_killed <= Global_Variables.high_score:
				add_theme_color_override("font_color", Color(1, 1, 0))  # Yellow
		else:
				add_theme_color_override("font_color", Color(0, 1, 0))  # Green
