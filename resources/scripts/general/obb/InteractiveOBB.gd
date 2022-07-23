extends "res://packages/fnfvr/resources/scripts/general/obb/OBB.gd"

signal touched
signal untouched

onready var main = get_tree().root.get_node("Main")

var pressed = false

func _process(_delta):
	if disabled:
		return
	
	var left_finger_press = has_point(main.player.left_index_point.global_transform.origin)
	var right_finger_press = has_point(main.player.right_index_point.global_transform.origin)
	
	if GodotX.xor(left_finger_press, right_finger_press):
		if pressed:
			return
		emit_signal("touched")
		pressed = true
	else:
		if !pressed:
			return
		emit_signal("untouched")
		pressed = false
