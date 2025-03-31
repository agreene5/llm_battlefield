extends Node

func _ready():
	Global_Variables.player_health = 100
	Global_Variables.teammate_health = 100

	Global_Variables.player_weapon = "basic"
	Global_Variables.teammate_weapon = "basic"
	Global_Variables.teammate_item = ""
	Global_Variables.player_item = ""

	Global_Variables.enemies_killed = 0

	Global_Variables.previous_action = "" # Defines what the teammate did previously
	Global_Variables._original_valid_actions = "" # Store the original list of actions
	Global_Variables.valid_actions = """
	Valid Actions (These are the ONLY actions you can choose from):
	- "fight" - Fights enemies
	- "use_health" - Heals health
	- "store_health" - Stores health in inventory
	- "equip_sword" - Equips a new sword
	- "store_sword" - Stores a sword in inventory
	- "transfer_item" - Transfers an item in inventory to the user
	- "use_stored_item" - Uses item stored in inventory
	- "move_to_player" - Moves towards the player
	- "new_location_move" - Moves towards a new location
	"""
