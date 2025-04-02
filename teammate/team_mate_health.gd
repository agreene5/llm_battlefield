extends Node

func _ready():
		# Connect to the Global_Variables signal
		Global_Variables.connect("enemy_attacked_teammate", _on_enemy_attacked)
		
func _physics_process(delta):
		$"../SubViewport/HealthBar3D".value = Global_Variables.teammate_health

func _on_enemy_attacked(enemy_name):
		if enemy_name.begins_with("first_enemy"):
					Global_Variables.teammate_health -= Global_Variables.enemy_1_damage
		elif enemy_name.begins_with("second_enemy"):
					Global_Variables.teammate_health -= Global_Variables.enemy_2_damage
		elif enemy_name.begins_with("third_enemy"):
					Global_Variables.teammate_health -= Global_Variables.enemy_3_damage
		
		# Play a random hurt sound effect
		var audio_player = $"../AudioStreamPlayer2D"
		var random_sfx = Global_Variables.hurt_sfx[randi() % Global_Variables.hurt_sfx.size()]
		audio_player.stream = load(random_sfx)
		audio_player.play()
		
		if Global_Variables.teammate_health <= 0:
				print("---Teammate dead---")
				get_parent().queue_free()
				get_tree().change_scene_to_file("res://main_menu.tscn")
