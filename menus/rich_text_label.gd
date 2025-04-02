extends RichTextLabel

func _ready():
	# Connect to the global signal
	Global_Variables.update_chat_display.connect(_on_update_chat_display)
	
	# Make sure BBCode is enabled
	bbcode_enabled = true
	
	# Optional: Set a default text or clear it
	text = ""
	
	# Optional: Set up some default properties if needed
	scroll_following = true  # Auto-scroll to follow new content

func _on_update_chat_display(action, message):
	# Clear the current text
	text = ""
	
	# If both action and message are empty, just keep it cleared
	if action.is_empty() and message.is_empty():
		return
	
	# Start building the BBCode text
	var formatted_text = ""
	
	# Add the action text in yellow with a black outline if it exists
	if not action.is_empty():
		formatted_text += "[outline_color=black][outline_size=1][color=yellow]" + action + "[/color][/outline_size][/outline_color]\n\n"
	
	# Add the message text
	if not message.is_empty():
		formatted_text += message
	
	# Set the formatted text to the RichTextLabel
	text = formatted_text
	
	# Optional: Ensure we're scrolled to the bottom to see latest messages
	scroll_to_line(get_line_count() - 1)
