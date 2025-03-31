extends Node2D

var controls_open = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_play_pressed():
	get_tree().change_scene_to_file("res://main.tscn")

func _on_controls_pressed():
	if not controls_open:
		controls_open = true
		$AnimationPlayer.play("Open_Controls")
	else:
		controls_open = false
		$AnimationPlayer.play("Close_Controls")

func _on_quit_pressed():
	get_tree().quit()
