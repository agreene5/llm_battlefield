extends Node2D

func _on_return_button_pressed():
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$PauseSong.stop()  # Stop instantly when unpausing
	visible = false

func _on_quit_button_pressed():
	$PauseSong.stop()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")

# Add this function to handle the pause action
func pause_game():
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$PauseSong.volume_db = -80  # Start very quiet
	$PauseSong.play()
	create_tween().tween_property($PauseSong, "volume_db", 0, 1.0)  # Fade in over 2 seconds
	visible = true
