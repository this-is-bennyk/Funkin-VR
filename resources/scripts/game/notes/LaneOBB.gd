extends "res://packages/fnfvr/resources/scripts/general/obb/InteractiveOBB.gd"

onready var lane = get_parent()

func _ready():
	connect("touched", self, "_on_obb_touched")
	connect("untouched", self, "_on_obb_untouched")

func _on_obb_touched():
	lane.check_input(true)

func _on_obb_untouched():
	lane.check_input(false)
