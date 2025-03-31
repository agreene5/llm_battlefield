extends Node

func _process(delta):
		# Check if the "E" key was just pressed
		if Input.is_action_just_pressed("e") and not Global_Variables.near_box:
				handle_item_interaction()

func handle_item_interaction():
		# Get the current item and weapon
		var current_item = Global_Variables.player_item
		var current_weapon = Global_Variables.player_weapon
		
		# Check if the current item is a health item
		if current_item == "health":
				# Add 30 to player health
				Global_Variables.player_health += 30
				# Optional: print confirmation
				print("Used health item. Health increased by 30.")
				# Optional: clear the item slot after using
				Global_Variables.player_item = null
		
		# Check if the current item is a weapon type
		elif current_item == "basic" or current_item == "uncommon" or current_item == "rare" or current_item == "epic" or current_item == "legendary":
				# Swap the weapon with the item
				var temp = current_weapon
				Global_Variables.player_weapon = current_item
				Global_Variables.player_item = temp
				# Optional: print confirmation
				print("Swapped " + str(current_item) + " weapon with " + str(temp))
		
