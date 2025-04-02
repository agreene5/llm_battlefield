extends Node

signal update_chat_display(action, message)

var player_position
var teammate_position

var player_health = 100
var teammate_health = 100 #100

var enemy_1_damage = 10
var enemy_2_damage = 15
var enemy_3_damage = 5

var HIGH = 2
var MED = 1
var LOW = 0

var player_weapon = "basic"
var teammate_weapon = "basic"

var pickup_item = false
var equip_item = false

var enemies_killed = 0
var high_score = 0

var near_box = false

var previous_action # Defines what the teammate did previously
var _original_valid_actions = "" # Store the original list of actions
var valid_actions = """
Valid Actions (These are the ONLY actions you can choose from):
- "use_health" - Heals health
- "store_health" - Stores health in inventory
- "equip_sword" - Equips a new sword
- "store_sword" - Stores a sword in inventory
- "transfer_item" - Transfers an item in inventory to the user
- "use_stored_item" - Uses item stored in inventory
- "fight" - Fights enemies
- "move_to_player" - Moves towards the player
- "new_location_move" - Moves towards a new location
"""

func randomize_valid_actions():
	# Store the original valid actions if we haven't already
	if _original_valid_actions.is_empty():
		_original_valid_actions = valid_actions
	
	# Always start with the original complete list
	var valid_actions_string = _original_valid_actions
	
	# Split the string into header and actions
	var parts = valid_actions_string.split("Valid Actions (These are the ONLY actions you can choose from):")
	if parts.size() < 2:
		print("Error: Could not find the header in the string")
		return
				
	var header = "Valid Actions (These are the ONLY actions you can choose from):"
	var actions_text = parts[1]
	
	# Split actions into individual items
	var actions_array = []
	var lines = actions_text.split("\n")
	
	for line in lines:
		if line.strip_edges().begins_with("-"):
			actions_array.append(line)
	
	# Check if previous_action is valid and remove it for this output only
	var found_previous_action = false
	var index_to_remove = -1
	
	if previous_action:
		for i in range(actions_array.size()):
			var line = actions_array[i]
			var action_start = line.find("\"")
			var action_end = line.find("\"", action_start + 1)
			
			if action_start != -1 and action_end != -1:
				var action_name = line.substr(action_start + 1, action_end - action_start - 1)
				if action_name == previous_action:
					found_previous_action = true
					index_to_remove = i
					break
		
		# Remove the previous_action if found
		if found_previous_action:
			actions_array.remove_at(index_to_remove)
		else:
			print("ERROR: Previous_Action isn't valid")
	
	# Check if teammate_item is null or empty and remove related actions
	if Global_Variables.teammate_item == null or Global_Variables.teammate_item == "":
		var i = 0
		while i < actions_array.size():
			var line = actions_array[i]
			var action_start = line.find("\"")
			var action_end = line.find("\"", action_start + 1)
			
			if action_start != -1 and action_end != -1:
				var action_name = line.substr(action_start + 1, action_end - action_start - 1)
				if action_name == "transfer_item" or action_name == "use_stored_item":
					actions_array.remove_at(i)
					continue  # Don't increment i since we removed an element
			i += 1
	
	# Randomize the array
	actions_array.shuffle()
	
	# Rebuild the string
	var randomized_actions = ""
	for action in actions_array:
		randomized_actions += action + "\n"
	
	# Set the valid_actions to the new randomized string
	valid_actions = header + "\n" + randomized_actions.strip_edges()

# 0-Damage,1-Color
var weapon_types = { 
	"basic" : [5, Color.SADDLE_BROWN], 
	"uncommon" : [10, Color.GREEN],
	"rare" : [20, Color.CYAN],
	"epic" : [35, Color.PURPLE],
	"legendary" : [50, Color.WHITE],
}

var player_item # What item the player has in storage
var teammate_item # What item the teammate has in storage
signal player_item_changed
signal teammate_item_changed

func set_player_item(value): # Run this function when changing player item to emit signal
	if player_item != value:
		player_item = value
		player_item_changed.emit()
		
func set_teammate_item(value): # Run this function when changing teammate item to emit signal
	if teammate_item != value:
		teammate_item = value
		teammate_item_changed.emit()

signal enemy_attacked_player(enemy_name) # For when enemy attacks player
signal enemy_attacked_teammate(enemy_name) # for when enemy attacks teammate

signal teammate_attacked_enemy(enemy)

func hand_player_item(item):
	if item in ["basic", "uncommon", "rare", "epic", "legendary"]:
		player_weapon = item
		print("player got new weapon: ", item)
	elif item == "health":
		player_health += 30
		print("player gained 30 health!")
		
func hand_teammate_item(item):
	if item in ["basic", "uncommon", "rare", "epic", "legendary"]:
		teammate_weapon = item
		print("teammate got new weapon: ", item)
	elif item == "health":
		teammate_health += 30
		print("teammate gained 30 health!")
		
signal environment_updated(info)

var can_pass_environment = true
var cooldown_timer = null

var user_input = false # if user is inputting smthn or just enviroment

func pass_enviroment_to_teammate():
		if can_pass_environment:
				var enviromental_info = Enviromental_Info.get_environmental_info()
				emit_signal("environment_updated", enviromental_info)
		
func pass_input_to_teammate(input):
		var enviromental_info = Enviromental_Info.get_environmental_info()
		var user_input = "PLAYER MESSAGE: Botson, " + input + "\nIMPORTANT: Your MUST follow the players instructions and respond DIRECTLY to the player."
		emit_signal("environment_updated", user_input)
		
		# Start cooldown timer
		can_pass_environment = false
		
		if cooldown_timer != null:
				cooldown_timer.queue_free()
		
		cooldown_timer = Timer.new()
		add_child(cooldown_timer)
		cooldown_timer.wait_time = 10.0 # 10 second cooldown after input is passed from user to prevent getting overrided
		cooldown_timer.one_shot = true
		cooldown_timer.connect("timeout", Callable(self, "_on_cooldown_timer_timeout"))
		cooldown_timer.start()

func _on_cooldown_timer_timeout():
		can_pass_environment = true
		cooldown_timer.queue_free()
		cooldown_timer = null
	
#-----------------------------------------------------------------------------------------------------------------------
# Define signals for each start function only
signal enemy_attacker_start_signal
signal health_box_start_signal(action)
signal weapon_box_start_signal(action)
signal pickup_item_start_signal
signal equip_item_start_signal
signal item_transferer_start_signal
signal player_follower_start_signal
signal use_stored_item_start_signal
signal default_behavior_start_signal
signal animation_behavior_start_signal(animation_name)
signal new_position_mover_start_signal
signal teleport_to_player_signal

# Global versions of the start functions that emit signals

func teleport_to_player():
	emit_signal("teleport_to_player_signal")

# Enemy attacker control function
func enemy_attacker_start():
		#print("1")
		emit_signal("enemy_attacker_start_signal")

# Health box seeker control function
func health_box_seeker_start(action):
		#print("2")
		emit_signal("health_box_start_signal", action)

# Weapon box seeker control function
func weapon_box_seeker_start(action):
		#print("3")
		emit_signal("weapon_box_start_signal", action)

# Item pickup control function
func pickup_item_start():
		#print("4")
		emit_signal("pickup_item_start_signal")

# Item equip control function
func equip_item_start():
		#print("5")
		emit_signal("equip_item_start_signal")

# Item transfer control function
func item_transferer_start():
		#print("6")
		emit_signal("item_transferer_start_signal")

# Player follower control function
func player_follower_start():
		#print("7")
		emit_signal("player_follower_start_signal")

# Use stored item control function
func use_stored_item_start():
		#print("8")
		emit_signal("use_stored_item_start_signal")

# Default behavior control function
func default_behavior_start():
		#print("9")
		emit_signal("default_behavior_start_signal")

# Animation behavior control function
func animation_behavior_start(animation_name):
		#print("10")
		emit_signal("animation_behavior_start_signal", animation_name)

func new_position_mover_start():
		#print("11")
		emit_signal("new_position_mover_start_signal")
		
		
var nested_dict = {
	"botson_health": {
		"0-30": ["YOU HAVE LOW HEALTH! HEAL SOON!", HIGH],
		"31-60": ["You have medium health", HIGH],
		"61-100": ["You have high health", HIGH],
	},
	"botson_weapon": {
		"basic": ["You have the weakest weapon, you should get an upgrade", MED],
		"uncommon": ["You have an ok weapon, you should get an upgrade", MED],
		"rare": ["You have a good weapon", LOW],
		"epic": ["You have a strong weapon", LOW],
		"legendary": ["You have the strongest weapon", LOW],
	},
	"botson_inventory": {
		"empty": ["You have no item stored", LOW],
		"heart": ["You have a health in storage", HIGH],
		"basic,uncommon,rare,epic,legendary": ["You have a sword in storage", HIGH],
	},
	"player_health": {
		"0-30": ["PLAYER HAS LOW HEALTH! GET THEM SOME HEALTH SOON!", HIGH],
		"31-60": ["Player has medium health", MED],
		"61-100": ["Player has high health", LOW],
	},
	"player_weapon": {
		"basic": ["Player has the weakest sword, you should get the player an upgrade", MED],
		"uncommon": ["Player has an ok sword, you should get the player an upgrade", MED],
		"rare": ["Player has a good sword", LOW],
		"epic": ["Player has a strong sword", LOW],
		"legendary": ["Player has the strongest sword", LOW],
	},
	"player_inventory": {
		"empty": ["Player has no item stored", LOW],
		"heart": ["Player has a heart in storage", MED],
		"basic,uncommon,rare,epic,legendary": ["Player has a sword in storage", MED],
	},
	"player_distance_to_botson": {
		"0-5": ["Player is close to you", HIGH],
		"6-10": ["Player is in your general vicinity", HIGH],
		"11-20": ["Player isn't close to you", MED],
		"21+": ["Player is far away from you", LOW],
	},
	"enemy_amount": {
		"0": ["There aren't any enemies present, now would be a good time to get a new sword", HIGH],
		"1-2": ["There are a few enemies present", MED],
		"3-5": ["There are some enemies present", MED],
		"6+": ["There are lots of enemies present", HIGH],
	},
	"nearest_enemy": {
		"0-3": ["THERE'S AN ENEMY(S) RIGHT ON TOP OF YOU!", HIGH],
		"4-8": ["There's an enemy(s) close to you!", HIGH],
		"9-15": ["There's an enemy(s) in your vicinity", MED],
		"16-25": ["Enemies aren't very close", MED],
		"25+": ["Enemies are far away", MED],
	},
	"health_box_amount": {
		"0": ["There's no health boxes present", LOW],
		"1": ["There's a health box present", MED],
		"2-3": ["There's health boxes present, maybe you should get one", MED],
	},
	"nearest_health_box": {
		"0-3": ["YOU'RE RIGHT ON TOP OF A HEALTH BOX! EQUIP OR PICK IT UP!", HIGH],
		"4-8": ["There's a health box nearby!", HIGH],
		"9-15": ["There's a health box in your vicinity", MED],
		"16-25": ["A health box isn't very close", MED],
		"25+": ["Health boxes are far away from you", MED],
	},
	"weapon_box_amount": {
		"0": ["There's no sword boxes present", LOW],
		"1": ["There's a swrd box present", MED],
		"2": ["There's sword boxes present, maybe you should get one", MED],
	},
	"nearest_weapon_box": {
		"0-3": ["YOU'RE RIGHT ON TOP OF A SWORD BOX! EQUIP OR PICK IT UP!", HIGH],
		"4-8": ["There's a sword box nearby!", HIGH],
		"9-15": ["There's a sword box in your vicinity", MED],
		"16-25": ["A sword box isn't very close", MED],
		"25+": ["Sword boxes are far away from you", MED],
	}
}

var hurt_sfx = [
	"res://Assets/Souns/ESC/Hurt_1.mp3",
	"res://Assets/Souns/ESC/Hurt_2.mp3",
	"res://Assets/Souns/ESC/Hurt_3.mp3"
]
var zombie_hurt_sfx = [
	"res://Assets/Souns/ESC/Zombie_Hurt_1.mp3",
	"res://Assets/Souns/ESC/Zombie_Hurt_2.mp3",
	"res://Assets/Souns/ESC/Zombie_Hurt_3.mp3"
]
var sword_slash_sfx = [
	"res://Assets/Souns/ESC/Sword_Slash_1.mp3",
	"res://Assets/Souns/ESC/Sword_Slash_2.mp3",
	"res://Assets/Souns/ESC/Sword_Slash_3.mp3"
]
