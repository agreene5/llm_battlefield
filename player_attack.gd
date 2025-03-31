extends Node

@onready var anim_player = $"../AnimationPlayer"
@onready var hitbox = $"../Head/Camera3D/WeaponPivot/WeaponMesh/Hitbox"
@onready var audio_player = $"../AudioStreamPlayer"

# Combo system variables
var current_combo = 0  # 0 = no combo, 1 = first attack, 2 = second attack, 3 = third attack
var combo_timer = 0.0
var combo_window_active = false
var next_attack_queued = false
var attack_cooldown = 0.0  # Cooldown between attacks when holding button


func _physics_process(delta):
		# Update attack cooldown
		if attack_cooldown > 0:
				attack_cooldown -= delta
		
		# Update combo timer if in combo window
		if combo_window_active:
				combo_timer -= delta
				if combo_timer <= 0 and not next_attack_queued:
						# Combo window expired, reset combo
						combo_window_active = false
						current_combo = 0
						if anim_player.current_animation != "Idle_Sword":
								anim_player.play("Idle_Sword")
		
		# Handle attack input
		if Input.is_action_pressed("attack") and attack_cooldown <= 0:
				var current_anim = anim_player.current_animation
				if current_anim == "Attack" or current_anim == "Attack2" or current_anim == "Attack3":
						# Queue the next attack
						next_attack_queued = true
				else:
						perform_attack()
						# Set a small cooldown to prevent extremely rapid attacks when holding
						attack_cooldown = 0.1

func perform_attack():
		hitbox.monitorable = true
		combo_window_active = false  # Deactivate combo window during attack
		next_attack_queued = false  # Reset the queue flag
		
		# Determine which attack to play based on current combo state
		if current_combo == 0 or current_combo == 3:
				# First attack in combo or after third attack
				anim_player.play("Attack")
				play_slash_sound(0)  # Play first sound
				current_combo = 1
		elif current_combo == 1:
				# Second attack in combo
				anim_player.play("Attack2")
				play_slash_sound(1)  # Play second sound
				current_combo = 2
		elif current_combo == 2:
				# Third attack in combo
				anim_player.play("Attack3")
				play_slash_sound(2)  # Play third sound
				current_combo = 3

func play_slash_sound(index):
		# Load and play the specific sound
		var sound_path = Global_Variables.sword_slash_sfx[index]
		var sound = load(sound_path)
		audio_player.stream = sound
		audio_player.play()

func _on_animation_player_animation_finished(anim_name):
		if anim_name == "Attack" or anim_name == "Attack2" or anim_name == "Attack3":
				hitbox.monitorable = false
				
				if anim_name == "Attack3":
						# After the third attack, reset combo
						current_combo = 0
						if next_attack_queued:
								perform_attack()  # Start a new combo if attack was queued
						else:
								anim_player.play("Idle_Sword")
				else:
						# Check if another attack was queued
						if next_attack_queued:
								perform_attack()  # Continue the combo immediately
						else:
								# Start combo timer
								combo_window_active = true
								combo_timer = 0.3
