extends NobodyWhoChat

var accumulated_response = ""
var current_display_text = ""
var final_display_text = ""
var max_chars_per_line = 50
var display_locked = false
var initial_connection = true

# New variables to handle user input interruption
var saved_user_input_message = ""
var waiting_for_current_response = false
var response_in_progress = false
var processing_deferred_message = false # New flag to track deferred processing

func _ready():
				print("DEBUG: Script initialized")
				Global_Variables.environment_updated.connect(_on_environment_updated)
				response_updated.connect(_on_response_updated)
				response_finished.connect(_on_response_finished)
				start_worker()
				
				# Set action label color to yellow
				var action_label = $"../NavigationRegion3D/TeamMate/Teammate_Action"
				action_label.modulate = Color(1, 1, 0)  # Yellow color (R=1, G=1, B=0)

func _on_environment_updated(message):
				print("DEBUG: Environment updated with message: ", message)
				send_message(message)

func send_message(message):
				print("DEBUG: send_message called with: ", message)
				print("DEBUG: user_input=", Global_Variables.user_input, 
								", saved_message=", saved_user_input_message,
								", waiting_for_response=", waiting_for_current_response,
								", response_in_progress=", response_in_progress,
								", processing_deferred=", processing_deferred_message)
				
				# Special handling for processing deferred saved message
				if processing_deferred_message:
								print("DEBUG: Processing deferred saved message")
								processing_deferred_message = false
								# Continue directly to message processing
				# Handle user_input priority messages
				elif Global_Variables.user_input:
								print("DEBUG: user_input is TRUE")
								# If this is the first message while user_input is true, save it
								if saved_user_input_message.is_empty():
												print("DEBUG: Saving first user_input message")
												saved_user_input_message = message
												# If a response is currently in progress, set flag to wait
												if response_in_progress:
																print("DEBUG: Response in progress, waiting to process saved message")
																waiting_for_current_response = true
																return
												print("DEBUG: No response in progress, continuing with saved message")
								else:
												# Ignore subsequent messages while user_input is true
												print("DEBUG: Ignoring subsequent message while user_input is true")
												return
				# If we're waiting for a response to finish, don't process new messages
				elif waiting_for_current_response:
								print("DEBUG: Waiting for current response to finish, ignoring new message")
								return
				
				# Process the saved message or the current message
				var msg_to_process = saved_user_input_message if !saved_user_input_message.is_empty() else message
				print("DEBUG: Processing message: ", msg_to_process)
				
				response_in_progress = true
				print("DEBUG: Setting response_in_progress to true")
				
				Global_Variables.randomize_valid_actions()
				if Global_Variables.previous_action != null:
								print("DEBUG: Sending message with previous action: ", Global_Variables.previous_action)
								say(msg_to_process + "\n" + Global_Variables.valid_actions + "\n" + "REMEMBER: Keep your actions and responses fresh and unique and keep track of health and weapon types. Also, avoid using this action: " + Global_Variables.previous_action)
								print("\n\n\n" + msg_to_process + "\n" + Global_Variables.valid_actions + "\n" + "REMEMBER: Keep your actions and responses fresh and unique and remember to keep track of health and weapon types")
				else:
								print("DEBUG: Sending message without previous action")
								say(msg_to_process + "\n" + Global_Variables.valid_actions)
								print("\n\n\n" + msg_to_process + "\n" + Global_Variables.valid_actions)
				# Reset for new message
				accumulated_response = ""
				current_display_text = ""
				final_display_text = ""
				display_locked = false
				
				# Clear the labels
				var label3d = $"../NavigationRegion3D/TeamMate/Teammate_Text"
				label3d.text = ""
				var action_label = $"../NavigationRegion3D/TeamMate/Teammate_Action"
				action_label.text = ""

func process_saved_message():
				print("DEBUG: process_saved_message called with saved message: ", saved_user_input_message)
				processing_deferred_message = true
				send_message(saved_user_input_message)

func _on_response_updated(token: String):
		# Simple debug to avoid excessive logging
		if accumulated_response.is_empty():
				print("DEBUG: First token received in response")
		
		# Always accumulate all tokens
		accumulated_response += token
		
		# If display is locked, don't update the Label3D
		if display_locked:
				return
		
		var text_label = $"../NavigationRegion3D/TeamMate/Teammate_Text"
		var action_label = $"../NavigationRegion3D/TeamMate/Teammate_Action"
		
		# Extract message using string pattern matching
		var message_pattern = "\"message\": \""
		var message_start = accumulated_response.find(message_pattern)
		
		if message_start != -1:
				message_start += message_pattern.length()
				var partial_message = accumulated_response.substr(message_start)
				var quote_end = partial_message.find("\"")
				
				if quote_end != -1:
						# We have a complete message field
						current_display_text = partial_message.substr(0, quote_end)
				else:
						# We have a partial message field that's still being streamed
						current_display_text = partial_message
				
				# Update the text label with current content
				text_label.text = format_text(current_display_text, max_chars_per_line)
		
		# Extract action using string pattern matching
		var action_pattern = "\"action\": \""
		var action_start = accumulated_response.find(action_pattern)
		
		if action_start != -1:
				action_start += action_pattern.length()
				var partial_action = accumulated_response.substr(action_start)
				var quote_end = partial_action.find("\"")
				
				if quote_end != -1:
						# We have a complete action field
						var action = partial_action.substr(0, quote_end)
						action_label.text = action
				else:
						# We have a partial action field that's still being streamed
						var action = partial_action
						action_label.text = action
				
				# Position the action label above the text
				position_action_label(action_label, text_label)

func _on_response_finished(response: String):
	print("DEBUG: Response finished with length: ", response.length())
	print("DEBUG: BEFORE - user_input=", Global_Variables.user_input, 
					", saved_message=", saved_user_input_message, 
					", waiting_for_response=", waiting_for_current_response,
					", response_in_progress=", response_in_progress)
	
	response_in_progress = false
	print("DEBUG: Set response_in_progress to false")
	
	# Clean up response to ensure it's valid JSON
	var cleaned_response = clean_json_string(response)
	
	var json = JSON.new()
	var error = json.parse(cleaned_response)
	
	if error == OK:
				var data = json.get_data()
				print("DEBUG: Parsed JSON data: ", data)
				
				var text_label = $"../NavigationRegion3D/TeamMate/Teammate_Text"
				var action_label = $"../NavigationRegion3D/TeamMate/Teammate_Action"
				
				# Display message in text label
				if data.has("message"):
							final_display_text = data.message
							text_label.text = format_text(final_display_text, max_chars_per_line)
				
				# Handle action if it exists
				if data.has("action"):
							var action = data.action
							print("DEBUG: Executing action: " + action)
							# Add this validation check
							var valid_actions = ["use_health", "store_health", "equip_sword", "store_sword", 
											   "transfer_item", "use_stored_item", "fight", 
											   "move_to_player", "new_location_move"]
							if not valid_actions.has(action):
								print("DEBUG: Invalid action detected: " + action + ", regenerating response")
								# Get the current message that needs to be reprocessed
								var current_msg = saved_user_input_message if !saved_user_input_message.is_empty() else Enviromental_Info.get_environmental_info()
								# Clear states to prevent loops
								saved_user_input_message = ""
								waiting_for_current_response = false
								response_in_progress = false
								# Resend the message to get a new response
								send_message(current_msg)
								return
							
							# Set action in the action label
							action_label.text = action
							
							# Position action label above text label
							position_action_label(action_label, text_label)
							
							# Set the action to previous_action before triggering it
							Global_Variables.previous_action = action
							call_deferred("trigger_action", action)
				else:
							# If no action, clear the action label
							action_label.text = ""
							print("RUNNING START WORKER 9704945")
							await get_tree().create_timer(1.5).timeout
							start_worker()
				
				# Parse animation but don't execute
				if data.has("animation"):
							var animation = data.animation
							print("DEBUG: Animation detected: " + animation + " (not playing)")
	else:
				print("DEBUG: JSON parse error: ", error)
				print("DEBUG: JSON error message: ", json.get_error_message())
				print("DEBUG: Invalid JSON: ", cleaned_response)
	
	print("DEBUG: Checking if we need to process saved message")
	# Handle the case where we were waiting for a response to finish
	if waiting_for_current_response:
				print("DEBUG: We were waiting for response to finish, now processing saved message")
				waiting_for_current_response = false
				# Use the special function to process the saved message
				call_deferred("process_saved_message")
				print("DEBUG: Called process_saved_message via call_deferred")
	# If this was the response to a user_input message, reset state
	elif !saved_user_input_message.is_empty() && !waiting_for_current_response:
				print("DEBUG: This was a response to a user_input message, resetting state")
				# Reset user_input flag and clear saved message
				var temp_message = saved_user_input_message
				saved_user_input_message = ""
				Global_Variables.user_input = false
				print("DEBUG: Reset user_input to false and cleared saved message: ", temp_message)
	
	print("DEBUG: AFTER - user_input=", Global_Variables.user_input, 
					", saved_message=", saved_user_input_message, 
					", waiting_for_response=", waiting_for_current_response,
					", response_in_progress=", response_in_progress)

func position_action_label(action_label, text_label):
		# Get current position of text label
		var text_pos = text_label.position
		
		# Calculate the number of lines in the text
		var lines = text_label.text.split("\n")
		var num_lines = max(1, lines.size())  # Ensure at least 1 line
		
		# Define base settings
		var base_offset = 0.75  # Minimum space between text and action labels
		var line_height = 0.07  # Height per line in world units
		
		# Calculate vertical offset based on number of lines
		# This scales with the text's height
		var vertical_offset = base_offset + (num_lines * line_height / 2)
		
		# Set action label position to be above text label
		action_label.position = Vector3(text_pos.x, text_pos.y + vertical_offset, text_pos.z)

func clean_json_string(json_str: String) -> String:
				# Look for opening brace
				var start = json_str.find("{")
				if start == -1:
								print("DEBUG: No opening brace found in JSON")
								return json_str  # No JSON found
				
				# Look for closing brace
				var end = json_str.rfind("}")
				if end == -1:
								print("DEBUG: No closing brace found in JSON")
								return json_str  # No JSON found
				
				# Extract just the JSON part
				return json_str.substr(start, end - start + 1)

func format_text(text: String, max_chars: int) -> String:
				var words = text.split(" ")
				var lines = []
				var current_line = ""
				
				for word in words:
								if current_line.length() + word.length() + 1 <= max_chars:
												if current_line.length() > 0:
																current_line += " " + word
												else:
																current_line = word
								else:
												lines.append(current_line)
												current_line = word
				
				if current_line.length() > 0:
								lines.append(current_line)
				
				return "\n".join(lines)

func trigger_animation(animation: String):
				if animation in ["bashful", "chicken_dance", "excited", "happy", "praying", "sad", "surprised"]:
								print("DEBUG: Animation function call would execute: " + animation)
								# Global_Variables.animation_behavior_start(animation)  # Commented out as requested

func trigger_action(action: String):
				print("DEBUG: In trigger_action with: " + action)
				match action.to_lower():
								"fight":
												Global_Variables.enemy_attacker_start()
								
								"use_health":
												Global_Variables.health_box_seeker_start("equip")
								
								"store_health":
												Global_Variables.health_box_seeker_start("pick_up")
								
								"equip_sword":
												Global_Variables.weapon_box_seeker_start("equip")
								
								"store_sword":
												Global_Variables.weapon_box_seeker_start("pick_up")
								
								"transfer_item":
												Global_Variables.item_transferer_start()
												
								"use_stored_item":
												Global_Variables.use_stored_item_start()
								
								"move_to_player":
												Global_Variables.player_follower_start()
								
								"new_location_move":
												Global_Variables.new_position_mover_start()
