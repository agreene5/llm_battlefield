extends Area3D


func _on_area_entered(area):
	if area.name == "TeamMate_Hitbox" or area.name == "Player_Area":
		print("Entered Death")
		get_tree().change_scene_to_file("res://main_menu.tscn")
