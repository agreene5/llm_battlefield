extends Node

@onready var damage_flash = $"../CanvasLayer/ColorRect"
@onready var audio_player = $"../AudioStreamPlayer2"

var flash_duration = 0.3  # How long the flash stays visible
var flash_timer = 0.0
var is_flashing = false

func _ready():
				# Connect to the Global_Variables signal
				Global_Variables.connect("enemy_attacked_player", _on_enemy_attacked)
				# Make sure the ColorRect is invisible at start
				damage_flash.visible = false

func _process(delta):
				# Handle the damage flash effect
				if is_flashing:
								flash_timer += delta
								
								# Create a pulsing effect by modulating the alpha value
								var alpha = 0.7 * (1.0 - (flash_timer / flash_duration))
								damage_flash.modulate = Color(1, 0, 0, alpha)
								
								# End the flash effect when timer is done
								if flash_timer >= flash_duration:
												is_flashing = false
												flash_timer = 0.0
												damage_flash.visible = false

func _on_enemy_attacked(enemy_name):
				print("\nATTACKED BY, ", enemy_name, "\n")
				if enemy_name.begins_with("first_enemy"):
						Global_Variables.player_health -= Global_Variables.enemy_1_damage
				elif enemy_name.begins_with("second_enemy"):
						Global_Variables.player_health -= Global_Variables.enemy_2_damage
				elif enemy_name.begins_with("third_enemy"):
						Global_Variables.player_health -= Global_Variables.enemy_3_damage
				
				# Play random hurt sound
				play_random_hurt_sound()
				
				# Trigger the damage flash effect
				damage_flash.visible = true
				damage_flash.modulate = Color(1, 0, 0, 0.7)  # Start with red at 70% opacity
				is_flashing = true
				flash_timer = 0.0
				
				if Global_Variables.player_health <= 0:
								print("---I'm dead---")
								get_tree().change_scene_to_file("res://main_menu.tscn")

func play_random_hurt_sound():
				# Get a random sound from the array
				var random_index = randi() % Global_Variables.hurt_sfx.size()
				var random_sound_path = Global_Variables.hurt_sfx[random_index]
				
				# Load and play the sound
				var sound = load(random_sound_path)
				audio_player.stream = sound
				audio_player.play()
