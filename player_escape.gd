# PauseController.gd
extends Node

signal typing_toggled(is_active)

@export var KEY_BIND_TYPING := "typer" # Key binding for typing mode

@onready var pause_menu = $"../CanvasLayer/Pause_Menu"
var is_paused = false
var typing_mode_active = false # Track if typing mode is active

func _ready():
	# Make sure the typing action exists
	if not InputMap.has_action(KEY_BIND_TYPING):
		InputMap.add_action(KEY_BIND_TYPING)
		var event = InputEventKey.new()
		event.keycode = KEY_T # Using T as default for typing
		InputMap.action_add_event(KEY_BIND_TYPING, event)
	
	# Make sure pause menu starts invisible
	pause_menu.visible = false
	
	# Ensure correct initial mouse mode
	set_typing_mode(false)

# Helper function to ensure typing mode and mouse mode always stay in sync
func set_typing_mode(enabled: bool):
	typing_mode_active = enabled
	
	# Always set the correct mouse mode based on typing state
	if typing_mode_active:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		print("Typing mode ON - Mouse VISIBLE")
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		print("Typing mode OFF - Mouse CAPTURED")
		
	typing_toggled.emit(typing_mode_active)

func _unhandled_input(event):
	# Handle pause toggle
	if event.is_action_pressed("escape"):
		print("PRESSED ESCAPE!!!!!!!!!!!!!!!!!!!!!!")
		toggle_pause()
		get_viewport().set_input_as_handled()
		return
	
	# Handle typing mode toggle using typer key
	if event.is_action_pressed(KEY_BIND_TYPING):
		set_typing_mode(!typing_mode_active)
		get_viewport().set_input_as_handled()
		return
	
	# Only process teleport if NOT in typing mode
	if not typing_mode_active and event.is_action_pressed("t"):
		print("TELEPORTING TO PLAYER")
		Global_Variables.teleport_to_player()
		get_viewport().set_input_as_handled()
		
func toggle_pause():
	# Toggle pause state
	is_paused = !is_paused
	
	if is_paused:
		# Use the new pause_game function when pausing
		pause_menu.pause_game()
		print("PAUSED - Mouse VISIBLE")
	else:
		# When unpausing, the return button handler will stop the music
		# But we need to handle the case when escaping out of the pause menu
		pause_menu.visible = false
		pause_menu.get_node("PauseSong").stop()
		get_tree().paused = false
		
		# When unpausing, respect the typing mode
		if typing_mode_active:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			print("UNPAUSED but still typing - Mouse VISIBLE")
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			print("UNPAUSED not typing - Mouse CAPTURED")

# Add this function to verify and fix mouse mode if it gets desynced
func _process(_delta):
	# Safety check to ensure mouse mode always matches typing state
	if typing_mode_active and Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		print("FIXED: Reset to VISIBLE mouse")
	elif !typing_mode_active and !is_paused and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		print("FIXED: Reset to CAPTURED mouse")
