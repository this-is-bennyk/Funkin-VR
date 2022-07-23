extends Spatial

export(NodePath) var beat_node
export(String) var anim

func _input(event):
	if event.is_action_pressed("ui_accept"):
		get_node(beat_node).play_anim(anim)
