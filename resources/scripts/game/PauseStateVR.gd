extends "res://scripts/game/PauseState.gd"

export(NodePath) var buttons_path

onready var main = get_tree().root.get_node("Main")
onready var lvl_manager = get_parent().get_parent().get_parent().get_parent()

var buttons_connected = false

# Previous _ready will be called at some point, doesn't matter when
func _ready():
	if buttons_connected:
		return
	
	for button in get_node(buttons_path).get_children():
		var down_event = InputEventAction.new()
		var up_event = InputEventAction.new()
		
		down_event.action = button.name.to_lower()
		up_event.action = down_event.action
		
		down_event.pressed = true
		up_event.pressed = false
		
		button.connect("button_down", self, "_on_button_changed", [down_event])
		button.connect("button_up", self, "_on_button_changed", [up_event])

func _process(delta):
	if !main.player.transition_system.is_playing():
		if db2linear(pause_music.volume_db) < 0.5:
			pause_music.volume_db = linear2db(db2linear(pause_music.volume_db) + 0.01 * delta)

func _on_button_changed(event):
	cur_menu.on_input(event)

func _unpause():
	lvl_manager.set_pause(false)

func _exit_level_premature(func_name):
	music_tween.interpolate_property(pause_music, "volume_db", pause_music.volume_db, linear2db(0.005), 0.7)
	
	main.player.play_transition("Basic_Fade_Out")
	main.player.connect("transition_finished", self, "_stop_music", [], CONNECT_DEFERRED | CONNECT_ONESHOT)
	main.player.connect("transition_finished", self, func_name, [], CONNECT_DEFERRED | CONNECT_ONESHOT)

func _restart(_trans_name):
	lvl_manager.restart()

func _quit_to_menu(_trans_name):
	lvl_manager.quit_to_menu()

func _return_control_to_pause_menu(_anim_name):
	._ready()
