extends Node

var temp_weapon

func start():
	if Global_Variables.teammate_item:
		print("Current Teammate Stored Weapon: " + Global_Variables.teammate_item)
	if Global_Variables.teammate_item in ["basic", "uncommon", "rare", "epic", "legendary"]:
		# Switching swords
		temp_weapon = Global_Variables.teammate_item
		Global_Variables.teammate_item = Global_Variables.teammate_weapon
		Global_Variables.teammate_weapon = temp_weapon
	elif Global_Variables.teammate_item == "heart":
		Global_Variables.teammate_item = "empty"
		Global_Variables.teammate_health += 30
	await get_tree().create_timer(1.0).timeout
	print("\n\n\nNew Teammate Weapon: ", Global_Variables.teammate_weapon)
	print("Current Teammate Stored Weapon: ", Global_Variables.teammate_item)
	Global_Variables.pass_enviroment_to_teammate()
	get_parent().default_behavior_start()
