extends "res://scripts/game/notes/Note3D.gd"

var player_note = false

func initialize_note():
	if note_type == Type.SUSTAIN_LINE || note_type == Type.SUSTAIN_CAP:
		get_node(note_model_path).hide()
		
		if note_type == Type.SUSTAIN_LINE:
			get_node(sustain_cap_model_path).hide()
			model = get_node(sustain_line_model_path)
		else:
			get_node(sustain_line_model_path).hide()
			model = get_node(sustain_cap_model_path)
		
		_update_sustain_length()
	
	else:
		get_node(sustain_line_model_path).hide()
		get_node(sustain_cap_model_path).hide()
		
		model = get_node(note_model_path)
		
		if player_note:
			model.rotation_degrees.z += 180
