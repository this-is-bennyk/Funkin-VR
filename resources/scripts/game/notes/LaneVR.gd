extends Lane

func spawn_note(note_instance):
	note_instance.player_note = (lane_type == Type.PLAYER || lane_type == Type.BOTPLAY)
	.spawn_note(note_instance)

# Downscroll is enforced for VR players, upscroll for opponents
func _adjust_for_downscroll():
	if lane_type != Type.PLAYER:
		return
	
	var this = get_parent().get_node(name)
	
	this.rotation_degrees.z += 180
	strum_arrow.rotation_degrees.z += 180
