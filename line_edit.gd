extends LineEdit

func _ready():
		# Only connect if not already connected
		if not text_submitted.is_connected(_on_text_submitted):
				text_submitted.connect(_on_text_submitted)

func _input(event):
	# Check if the "typing" action was just pressed
	if Input.is_action_just_pressed("typer"):
		if has_focus():
			# If already focused, release focus
			release_focus()
		else:
			# If not focused, grab focus
			grab_focus()

func _on_text_submitted(new_text):
	Global_Variables.user_input = true
	submit_text()

# Function to submit the text to the Global_Variables function
func submit_text():
	if text.strip_edges() != "":
		Global_Variables.pass_input_to_teammate(text)
		clear()  # Clear the input field after submission
