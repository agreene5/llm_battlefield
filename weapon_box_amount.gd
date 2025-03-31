extends Label

func _physics_process(delta):
		var enemy_count = get_tree().get_nodes_in_group("Weapon_Box").size()
		text = "Weapon Boxes: " + str(enemy_count)
