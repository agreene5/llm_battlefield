extends CollisionShape3D

@export var target_skeleton_path: NodePath
@export var bone_name: String = "J_Bip_C_Spine" # Change to match your skeleton's spine bone name

var skeleton: Skeleton3D
var bone_idx: int = -1

func _ready():
	if target_skeleton_path.is_empty():
		push_warning("Target skeleton path not set")
		return
		
	skeleton = get_node(target_skeleton_path)
	if not skeleton:
		push_warning("Could not find skeleton at specified path")
		return
	
	# Find the bone index
	for i in range(skeleton.get_bone_count()):
		if bone_name.to_lower() in skeleton.get_bone_name(i).to_lower():
			bone_idx = i
			break
	
	if bone_idx == -1:
		push_warning("Bone '" + bone_name + "' not found in skeleton")

func _process(delta):
	if bone_idx != -1 and skeleton:
		# Get the global transform of the target bone
		var bone_global_pos = skeleton.get_bone_global_pose(bone_idx).origin
		
		# Convert to global space, then back to local space relative to our parent
		var global_pos = skeleton.to_global(bone_global_pos)
		var local_pos = get_parent().to_local(global_pos)
		
		# Update only the position of the collision shape
		position = local_pos
