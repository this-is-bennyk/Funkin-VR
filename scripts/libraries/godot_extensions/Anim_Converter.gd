extends Spatial

func _ready():
	convert_anim()

func convert_anim():
	var anim: Animation = $AnimationPlayer.get_animation("Dance_Left")
	var anim_file = File.new()
	
	anim_file.open("res://assets/models/chars/gf/GF_Dance_Left.txt", File.WRITE)
	anim_file.store_line(name + ": Dance_Left")
	anim_file.store_line("--------------------------------------")
	anim_file.store_line("Framerate: 24 FPS")
	anim_file.store_line("Length in frames: " + str(int(round(anim.length * 24))))
	anim_file.store_line("--------------------------------------")
	
	for track_idx in anim.get_track_count():
		var nodepath = str(anim.track_get_path(track_idx))
		var spacer = "\n" if track_idx > 0 else ""
		anim_file.store_line(spacer + nodepath)
		
		var split_nodepath = nodepath.split(":")
		
		if split_nodepath[split_nodepath.size() - 1].find("blend_shapes") == -1:
			var cur_bone = $"Girlfriend Armature/Skeleton2".find_bone(split_nodepath[split_nodepath.size() - 1])
			
			var rest_pose = $"Girlfriend Armature/Skeleton2".get_bone_rest(cur_bone)
			
			for key_idx in anim.track_get_key_count(track_idx):
				var frame = int(round(anim.track_get_key_time(track_idx, key_idx) * 24))
				var pose_xform_dict = anim.track_get_key_value(track_idx, key_idx)
				var pose_xform = Transform(Basis(Quat(pose_xform_dict.rotation)).scaled(pose_xform_dict.scale), pose_xform_dict.location)
				var final_xform = rest_pose * pose_xform
				
				var orig = final_xform.origin
				var quat = final_xform.basis.get_rotation_quat()
				var scle = final_xform.basis.get_scale()
				
				anim_file.store_line("\tFrame " + str(frame) + ": " + str(orig).substr(1, len(str(orig)) - 2) + \
															   ", " + str(quat).substr(1, len(str(quat)) - 2) + \
															   ", " + str(scle).substr(1, len(str(scle)) - 2))
		else:
			for key_idx in anim.track_get_key_count(track_idx):
				var frame = int(round(anim.track_get_key_time(track_idx, key_idx) * 24))
				anim_file.store_line("\tFrame " + str(frame) + ": " + str(anim.track_get_key_value(track_idx, key_idx)))
	
	anim_file.close()
