extends Spatial

const LEVEL_MANAGER = preload("res://packages/fnfvr/resources/scenes/game/LevelManagerVR.tscn")

export(String, FILE) var path

onready var main = get_parent()

func _ready():
	if main.player.origin.auto_initialise:
		$Viewport/CanvasLayer/Label.text = "Touch OBB to play:\n" + path
		$OBB.connect("touched", self, "_on_OBB_touched", [], CONNECT_DEFERRED | CONNECT_ONESHOT)
		main.player.play_transition("Basic_Fade_In")
		return
	
	_on_OBB_touched()

func _on_OBB_touched():
#	var song_data: SongData = load(path)
#
	var level_manager_args = {
		"difficulty": 2,
		"story_mode_path": "res://packages/fnfvr/testing/LevelTester.tscn"
	}
#
#	get_parent().switch_state(LEVEL_MANAGER, level_manager_args)
	
	get_parent().switch_state(path, level_manager_args)
