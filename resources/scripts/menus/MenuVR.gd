extends "res://packages/fnfvr/resources/scripts/general/scene_scaling/SceneScaler.gd"

export(NodePath) var viewport_path

onready var viewport = get_node(viewport_path)

func _input(event):
	if event is InputEventAction:
		viewport.input(event)
