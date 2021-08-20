tool
extends Skeleton

export(bool) var update = false setget update_animation

export(NodePath) var anim_player_path
export(String) var anim_name
export(String) var track_nodepath

# Assumption: we are only animating in 24 FPS
export(int) var frame = 0 setget update_editor_info

export(Vector3) var pose_origin = Vector3()
export(Vector3) var pose_rotation_degrees = Vector3()
export(Vector3) var pose_scale = Vector3.ONE

func update_animation(bool_):
	if !Engine.editor_hint:
		return
	
	if !anim_player_path || !anim_name || !track_nodepath:
		print("Error: You must fill out all of the animation parameters to set a new key.")
		return
	
	var anim_player = get_node(anim_player_path)
	
	if !(anim_player is AnimationPlayer):
		print("Error: Not an AnimationPlayer.")
		return
	
	if !(anim_player.has_animation(anim_name)):
		print("Error: No such animation named " + anim_name + ".")
		return
	
	var anim: Animation = anim_player.get_animation(anim_name)
	
	if anim.find_track(track_nodepath) == -1:
		anim.add_track(Animation.TYPE_TRANSFORM)
		anim.track_set_path(anim.get_track_count() - 1, track_nodepath)
	
	# Assumption: we are only working with transform tracks.

	var pose_rotation = Vector3(deg2rad(pose_rotation_degrees.x), deg2rad(pose_rotation_degrees.y), deg2rad(pose_rotation_degrees.z))
	# This. This one line is the reason we have to do this in the first fuckin place.
	# You cannot normalize a quaternion in the animation editor.
	var pose_quat = Quat(pose_rotation).normalized()

	anim.transform_track_insert_key(anim.find_track(track_nodepath), frame / 24.0, pose_origin, pose_quat, pose_scale)

func update_editor_info(f):
	frame = f
	
	if !Engine.editor_hint:
		return
	
	if !anim_player_path || !anim_name || !track_nodepath:
		print("Error: You must fill out all of the animation parameters to get a key's value.")
		return
	
	var anim_player = get_node(anim_player_path)
	
	if !(anim_player is AnimationPlayer):
		print("Error: Not an AnimationPlayer.")
		return
	
	if !(anim_player.has_animation(anim_name)):
		print("Error: No such animation named " + anim_name + ".")
		return
	
	var anim: Animation = anim_player.get_animation(anim_name)
	
	var track_idx = anim.find_track(track_nodepath)
	
	if track_idx == -1:
		print("Error: No track with path " + track_nodepath + " found.")
		return
	
	var key_idx = anim.track_find_key(track_idx, frame / 24.0, true)
#	print("Actual key index: " + str(key_idx))
	
	if key_idx == -1:
		print("Error: No key at frame " + str(frame) + " found.")
		return
	
	var transform_dict = anim.track_get_key_value(track_idx, key_idx)
	
	pose_origin = transform_dict.location
	
	var pose_rotation = transform_dict.rotation.get_euler()
	pose_rotation_degrees = Vector3(rad2deg(pose_rotation.x), rad2deg(pose_rotation.y), rad2deg(pose_rotation.z))
	
	pose_scale = transform_dict.scale

