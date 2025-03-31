extends Area3D

var cooldown_period = false
var elapsed_time = 0

func _ready():
	no_monitor()

func no_monitor():
	monitorable = false

func _process(delta):
	elapsed_time += delta
	if elapsed_time >= 0.5:
		print("Montirable Property: ", monitorable)
		elapsed_time = 0  # Reset the counter

func _on_area_entered(area):
		print("1. Area Entered: ", area)
		if area.name == "Enemy_Hitbox" and not cooldown_period:
				print("<<<<<<<<<<<<on cooldown period------")
				monitorable = false
				cooldown_period = true

				

func _on_area_exited(area):
	if area.name == "Enemy_Hitbox":
		pass
