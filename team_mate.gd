extends CharacterBody3D

const SPEED = 4.0
const MOVEMENT_THRESHOLD = 0.1  # Threshold to determine if character is moving

@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree
@onready var sword_hitbox = $Armature/Skeleton3D/BoneAttachment3D/MeshInstance3D/TeamMate_Sword_Hitbox
@onready var enemy_attacker = $EnemyAttacker
@onready var health_box_seeker = $HealthBoxSeeker
@onready var weapon_box_seeker = $WeaponBoxSeeker
@onready var item_pickupper = $ItemPickUpper
@onready var item_equipper = $ItemEquipper
@onready var item_transferer = $ItemTransferer
@onready var player_follower = $PlayerFollower
@onready var use_stored_item = $UseStoredItem
@onready var default_behavior = $DefaultBehavior
@onready var animation_behavior = $AnimationBehavior
@onready var new_position_mover = $NewPositionMover

var state_machine
var character_health = 100
var active_behavior = null

var _animation_updates_enabled = true

func _ready():
		Global_Variables.connect("enemy_attacker_start_signal", Callable(self, "enemy_attacker_start"))
		Global_Variables.connect("health_box_start_signal", Callable(self, "health_box_start"))
		Global_Variables.connect("weapon_box_start_signal", Callable(self, "weapon_box_start"))
		Global_Variables.connect("pickup_item_start_signal", Callable(self, "pickup_item_start"))
		Global_Variables.connect("equip_item_start_signal", Callable(self, "equip_item_start"))
		Global_Variables.connect("item_transferer_start_signal", Callable(self, "item_transferer_start"))
		Global_Variables.connect("player_follower_start_signal", Callable(self, "player_follower_start"))
		Global_Variables.connect("use_stored_item_start_signal", Callable(self, "use_stored_item_start"))
		Global_Variables.connect("default_behavior_start_signal", Callable(self, "default_behavior_start"))
		Global_Variables.connect("animation_behavior_start_signal", Callable(self, "animation_behavior_start"))
		Global_Variables.connect("new_position_mover_start_signal", Callable(self, "new_position_mover_start"))
		
		Global_Variables.connect("teleport_to_player_signal", Callable(self, "teleport_to_player"))
		
		state_machine = anim_tree.get("parameters/playback")
		
		# Disable processing for all behavior nodes
		disable_all_behaviors_processing()
		
		await get_tree().create_timer(2.0).timeout
		
		# Start with health box behavior
		default_behavior_start()
		Global_Variables.pass_enviroment_to_teammate()
		
func teleport_to_player():
	position = Global_Variables.player_position + Vector3(0, 0, 1)
		
		
# Disable processing for all behavior nodes
func disable_all_behaviors_processing():
		enemy_attacker.set_process(false)
		health_box_seeker.set_process(false)
		weapon_box_seeker.set_process(false)
		item_pickupper.set_process(false)
		item_equipper.set_process(false)
		item_transferer.set_process(false)
		player_follower.set_process(false)
		use_stored_item.set_process(false)
		default_behavior.set_process(false)
		animation_behavior.set_process(false)
		new_position_mover.set_process(false)

func _process(delta):
		# Constrain rotation to prevent tipping over (max 10 degrees on X and Z)
		var current_rotation = rotation_degrees
		if abs(current_rotation.x) > 10:
				rotation_degrees.x = 10 * sign(current_rotation.x)
		if abs(current_rotation.z) > 10:
				rotation_degrees.z = 10 * sign(current_rotation.z)
		# Update animations based on movement and active behavior
		update_animations()
		
		# Apply movement
		move_and_slide()
	

func update_animations():
	if !_animation_updates_enabled:
		return
				
	# First, reset all animation conditions
	anim_tree.set("parameters/conditions/run", false)
	anim_tree.set("parameters/conditions/attack", false)
	anim_tree.set("parameters/conditions/idle", false)
	
	# Check if character is actually moving
	var is_moving = velocity.length() > MOVEMENT_THRESHOLD
	
	if active_behavior == default_behavior:
		# Set only the appropriate condition based on behavior
		if default_behavior.should_attack():
			# Set attack condition
			anim_tree.set("parameters/conditions/attack", true)
		elif is_moving:
			# Set run condition
			anim_tree.set("parameters/conditions/run", true)
		else:
			# Set idle condition
			anim_tree.set("parameters/conditions/idle", true)
			
		# Make sure we're not in any special states that need back_idle
		anim_tree.set("parameters/conditions/back_idle", true)
		
		# Make sure other special conditions are off
		anim_tree.set("parameters/conditions/hand_item", false)
		anim_tree.set("parameters/conditions/pick_up", false)
	
	elif active_behavior == enemy_attacker:
		# Handle enemy attacker animations
		if enemy_attacker.should_attack():
			# Set attack condition
			anim_tree.set("parameters/conditions/attack", true)
		elif is_moving:
			# Set run condition
			anim_tree.set("parameters/conditions/run", true)
		else:
			# Set idle condition
			anim_tree.set("parameters/conditions/idle", true)
		
		# Make sure we're not in any special states that need back_idle
		anim_tree.set("parameters/conditions/back_idle", true)
		
		# Make sure other special conditions are off
		anim_tree.set("parameters/conditions/hand_item", false)
		anim_tree.set("parameters/conditions/pick_up", false)
		
	elif active_behavior == item_transferer:
		# Handle item transferer animations
		if item_transferer.should_hand_item():
			# Set hand_item condition
			anim_tree.set("parameters/conditions/hand_item", true)
			anim_tree.set("parameters/conditions/idle", true)
			anim_tree.set("parameters/conditions/run", false)
			anim_tree.set("parameters/conditions/attack", false)
			anim_tree.set("parameters/conditions/back_idle", false)
		elif is_moving || item_transferer.should_run():
			# Set run condition
			anim_tree.set("parameters/conditions/run", true)
			anim_tree.set("parameters/conditions/idle", false)
			anim_tree.set("parameters/conditions/hand_item", false)
			anim_tree.set("parameters/conditions/attack", false)
			anim_tree.set("parameters/conditions/back_idle", false)
		else:
			# Set idle condition
			anim_tree.set("parameters/conditions/idle", true)
			anim_tree.set("parameters/conditions/back_idle", true)
			anim_tree.set("parameters/conditions/hand_item", false)
			anim_tree.set("parameters/conditions/run", false)
			anim_tree.set("parameters/conditions/attack", false)
			
	elif active_behavior == player_follower:
		# Handle player follower animations
		if player_follower.should_run():
			# Set run condition
			anim_tree.set("parameters/conditions/run", true)
			anim_tree.set("parameters/conditions/idle", false)
		else:
			# Set idle condition
			anim_tree.set("parameters/conditions/idle", true)
			anim_tree.set("parameters/conditions/run", false)
		
		# Other conditions should be off
		anim_tree.set("parameters/conditions/attack", false)
		anim_tree.set("parameters/conditions/hand_item", false)
		anim_tree.set("parameters/conditions/pick_up", false)
		anim_tree.set("parameters/conditions/back_idle", true)
		
	elif active_behavior == item_pickupper or item_equipper:
		# Let the pickup behavior handle animations
		return
func trigger_attack_animation():
	anim_tree.set("parameters/conditions/attack", true)
	anim_tree.set("parameters/conditions/run", false)
	anim_tree.set("parameters/conditions/idle", false)

func disable_animation_updates():
		_animation_updates_enabled = false

func enable_animation_updates():
		_animation_updates_enabled = true


# Enemy attacker control functions
func enemy_attacker_start():
	stop_all_behaviors()
	active_behavior = enemy_attacker
	enemy_attacker.set_process(true)
	enemy_attacker.start()

func enemy_attacker_end():
	enemy_attacker.stop()
	enemy_attacker.set_process(false)
	if active_behavior == enemy_attacker:
		active_behavior = null

# Health box seeker control functions
func health_box_start(action):
	stop_all_behaviors()
	active_behavior = health_box_seeker
	health_box_seeker.set_process(true)
	health_box_seeker.start(action)

func health_box_end():
	health_box_seeker.stop()
	health_box_seeker.set_process(false)
	if active_behavior == health_box_seeker:
		active_behavior = null

# Weapon box seeker control functions
func weapon_box_start(action):
	stop_all_behaviors()
	active_behavior = weapon_box_seeker
	weapon_box_seeker.set_process(true)
	weapon_box_seeker.start(action)

func weapon_box_end():
	weapon_box_seeker.stop()
	weapon_box_seeker.set_process(false)
	if active_behavior == weapon_box_seeker:
		active_behavior = null

# Item pickup control functions
func pickup_item_start():
	stop_all_behaviors()
	active_behavior = item_pickupper
	item_pickupper.set_process(true)
	item_pickupper.start()

func pickup_item_end():
	item_pickupper.stop()
	item_pickupper.set_process(false)
	if active_behavior == item_pickupper:
		active_behavior = null

# Item equip control functions
func equip_item_start():
	stop_all_behaviors()
	active_behavior = item_equipper
	item_equipper.set_process(true)
	item_equipper.start()

func equip_item_end():
	item_equipper.stop()
	item_equipper.set_process(false)
	if active_behavior == item_equipper:
		active_behavior = null
		
func item_transferer_start():
	stop_all_behaviors()
	active_behavior = item_transferer
	item_transferer.set_process(true)
	item_transferer.start()
	
func item_transferer_end():
	item_transferer.stop()
	item_transferer.set_process(false)
	if active_behavior == item_transferer:
		active_behavior = null

# Player follower control functions
func player_follower_start():
	stop_all_behaviors()
	active_behavior = player_follower
	player_follower.set_process(true)
	player_follower.start()
	
func player_follower_end():
	player_follower.stop()
	player_follower.set_process(false)
	if active_behavior == player_follower:
		active_behavior = null
		
func use_stored_item_start():
	stop_all_behaviors()
	active_behavior = use_stored_item
	use_stored_item.set_process(true)
	use_stored_item.start()

func default_behavior_start():
	stop_all_behaviors()
	active_behavior = default_behavior
	default_behavior.set_process(true)
	default_behavior.start()

func default_behavior_end():
	default_behavior.stop()
	default_behavior.set_process(false)
	if active_behavior == default_behavior:
		active_behavior = null

func animation_behavior_start(animation_name):
	stop_all_behaviors()
	active_behavior = animation_behavior
	animation_behavior.set_process(true)
	animation_behavior.start(animation_name)

func animation_behavior_end():
	animation_behavior.stop()
	animation_behavior.set_process(false)
	if active_behavior == animation_behavior:
		active_behavior = null

func new_position_mover_start():
	stop_all_behaviors()
	active_behavior = new_position_mover
	animation_behavior.set_process(true)
	animation_behavior.start()
	
func new_position_mover_end():
	animation_behavior.stop()
	animation_behavior.set_process(false)
	if active_behavior == new_position_mover:
		active_behavior = null

# Helper function to stop all behaviors
func stop_all_behaviors():
		enemy_attacker.stop()
		health_box_seeker.stop()
		weapon_box_seeker.stop()
		item_transferer.stop()
		player_follower.stop()
		default_behavior.stop()
		animation_behavior.stop()
		new_position_mover.start()
		enemy_attacker.set_process(false)
		health_box_seeker.set_process(false)
		weapon_box_seeker.set_process(false)
		item_pickupper.set_process(false)
		item_equipper.set_process(false)
		item_transferer.set_process(false)
		player_follower.set_process(false)
		default_behavior.set_process(false)
		animation_behavior.set_process(false)
		new_position_mover.set_process(false)
		
		active_behavior = null

func _on_team_mate_hitbox_area_entered(area):
		if area.is_in_group("enemy_hitbox"):
				character_health -= 10
				if character_health <= 0:
						print("Character Dead")
						queue_free()
				#print("Hit! Health: ", character_health)

# Function to allow external control of animations
func set_animation_state(anim_name):
	if state_machine:
		state_machine.travel(anim_name)
