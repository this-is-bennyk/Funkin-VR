extends Control

export var button_list = []

func _ready():
	for btn_nodepath in button_list:
		var btn = get_node(btn_nodepath)
		btn.connect("gui_input", self, "_on_button_gui_input")
#		btn.connect("mouse_entered", self, "_on_mouse_entered_button")
#		btn.connect("mouse_exited", self, "_on_mouse_exited_button")
#		btn.connect("pressed", self, "_on_button_pressed")

func _on_button_gui_input(event):
	if event is InputEventMouseButton:
		pass

#func _on_mouse_entered_button(btn):
#	btn.get_node("AnimationPlayer").play("Hover")
#
#func _on_mouse_exited_button(btn):
#	btn.get_node("AnimationPlayer").play("Normal")
#
#func _on_button_pressed(btn):
#	btn.get_node("AnimationPlayer").play("Selected")
