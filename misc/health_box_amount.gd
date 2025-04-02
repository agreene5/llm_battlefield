extends Label

func _physics_process(delta):
		var enemy_count = get_tree().get_nodes_in_group("Health_Box").size()
		text = "Health Boxes: " + str(enemy_count)
