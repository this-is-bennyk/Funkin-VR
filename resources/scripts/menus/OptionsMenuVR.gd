extends Control

export(NodePath) var buttons_path

onready var options_ui = $OptionsUI

func _ready():
	for button in get_node(buttons_path).get_children():
		var down_event = InputEventAction.new()
		var up_event = InputEventAction.new()
		
		down_event.action = button.name.to_lower()
		up_event.action = down_event.action
		
		down_event.pressed = true
		up_event.pressed = false
		
		button.connect("button_down", self, "_on_button_changed", [down_event])
		button.connect("button_up", self, "_on_button_changed", [up_event])

func _on_button_changed(event):
	options_ui.on_input(event)
