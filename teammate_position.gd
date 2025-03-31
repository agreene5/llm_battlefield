extends Node

func _physics_process(delta):
	Global_Variables.teammate_position = get_parent().position
