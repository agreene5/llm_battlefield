extends Button

func _ready():
		# Set button text
		text = "Submit"
		
		# Connect the pressed signal
		pressed.connect(_on_pressed)

func _on_pressed():
		# Call the parent LineEdit's submit_text function
		var line_edit = get_parent()
		if line_edit is LineEdit:
				line_edit.submit_text()
