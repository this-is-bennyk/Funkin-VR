extends Node

signal frame_tick
signal physics_tick
signal unhandled_input_event(ev)

func _process(delta):
	emit_signal("frame_tick")

func _physics_process(delta):
	emit_signal("physics_tick")

func _unhandled_input(event):
	emit_signal("unhandled_input_event", event)
