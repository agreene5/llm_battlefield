extends Node

func _process(delta):
		var distance_to_teammate = get_parent().global_position.distance_to(Global_Variables.teammate_position)
		
		if distance_to_teammate <= 3.0 and Global_Variables.player_item in ["basic", "uncommon", "rare", "epic", "legendary", "health"]:
			$"../CanvasLayer/Hand_Item_Label".visible = true
			if Input.is_action_just_pressed("q"):
					Global_Variables.hand_teammate_item(Global_Variables.player_item)
					Global_Variables.set_player_item("")
		else:
			$"../CanvasLayer/Hand_Item_Label".visible = false
