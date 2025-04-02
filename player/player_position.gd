extends Node

func _physics_process(delta):
	Global_Variables.player_position = get_parent().position
