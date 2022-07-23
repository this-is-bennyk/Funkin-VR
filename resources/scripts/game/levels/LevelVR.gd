extends "res://scripts/game/Level.gd"

onready var main = get_tree().root.get_node("Main")

func set_preload_variables():
	countdown_voices = [
		preload("res://assets/sounds/introGo.ogg"),
		preload("res://assets/sounds/intro1.ogg"),
		preload("res://assets/sounds/intro2.ogg"),
		preload("res://assets/sounds/intro3.ogg")
	]
	
	popup_combo = preload("res://packages/fnfvr/resources/scenes/game/PopupComboVR.tscn")
	
	miss_sounds = [
		preload("res://assets/sounds/missnote1.ogg"),
		preload("res://assets/sounds/missnote2.ogg"),
		preload("res://assets/sounds/missnote3.ogg")
	]

func handle_prev_transition():
	match main.player.transition_system.assigned_animation:
		"Instant_Fade_Out":
			main.player.play_transition("Instant_Fade_In")
		_:
			main.player.play_transition("Basic_Fade_In")

func do_post_level_story_event():
	if lvl_manager.in_last_state():
		transition_to_level_exit()
	else:
		main.player.play_transition("Instant_Fade_Out")
		main.player.connect("transition_finished", self, "end_level_part_2", [], CONNECT_DEFERRED | CONNECT_ONESHOT)

func transition_to_level_exit():
	set_process(false)
	set_process_input(false)
	
	main.player.play_transition("Basic_Fade_Out")
	main.player.connect("transition_finished", self, "end_level_part_2", [], CONNECT_DEFERRED | CONNECT_ONESHOT)

func on_input(event: InputEvent):
	.on_input(event)
	if !get_tree().paused:
		if can_pause && event is InputEventJoypadButton && (event.button_index == JOY_OCULUS_AX || event.button_index == JOY_OPENVR_MENU):
			lvl_manager.set_pause(true)
			return
