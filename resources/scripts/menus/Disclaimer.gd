extends Spatial

onready var main = get_tree().root.get_node("Main")
onready var button = $MenuVR/Viewport/Button

func _input(event):
	if event.is_action_pressed("ui_accept"):
		_on_button_pressed()
		set_process_input(false)

func _on_button_pressed():
	button.disabled = true
	main.player.play_transition("Basic_Fade_Out")
	main.player.connect("transition_finished", self, "_switch_to_main_menu", [], CONNECT_DEFERRED | CONNECT_ONESHOT)

func _switch_to_main_menu(_trans_name):
	main.switch_state("res://packages/fnfvr/resources/scenes/menus/Main_Menu.tscn")
