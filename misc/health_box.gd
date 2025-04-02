extends MeshInstance3D

var player_in_range = false
var teammate_in_range = false
var lifetime_timer = 0.0

func _ready():
	# Initialize the lifetime timer
	lifetime_timer = 0.0

func _process(delta):
	# Update lifetime timer
	lifetime_timer += delta
	
	# Check if lifetime exceeded 90 seconds
	if lifetime_timer >= 90.0:
		queue_free()
		return
		
	if player_in_range:
		if Input.is_action_just_pressed("r"):
			#print("USED HEALTH!")
			Global_Variables.player_health += 30
			queue_free()
		if Input.is_action_just_pressed("e"):
			Global_Variables.set_player_item("health")
			#print("Picked Up Health!!")
			queue_free()
	if teammate_in_range:
		if Global_Variables.equip_item:
			#print("TEAMMATE GAINED HEALTH!!!")
			Global_Variables.teammate_health += 30
			queue_free()
		elif Global_Variables.pickup_item:
			Global_Variables.set_teammate_item("health")
			#print("TEAMMATE PICKED UP HEALTH!!!")
			queue_free()

func _on_health_box_area_area_entered(area):
	if area.name == "Player_Area":
		Global_Variables.near_box = true
		player_in_range = true
	if area.name == "TeamMate_Hitbox":
		teammate_in_range = true

func _on_health_box_area_area_exited(area):
	if area.name == "Player_Area":
		Global_Variables.near_box = false
		player_in_range = false
	if area.name == "TeamMate_Hitbox":
		teammate_in_range = false
