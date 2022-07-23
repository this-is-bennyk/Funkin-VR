extends Spatial

const LEVEL_MANAGER = preload("res://packages/fnfvr/resources/scenes/game/LevelManagerVR.tscn")
const FREAKY_MENU = preload("res://assets/music/freakyMenu.ogg")

export(Array, NodePath) var state_paths
export(Array, NodePath) var sound_paths

onready var main = get_tree().root.get_node("Main")
onready var gui_obb = $MenuVR/Display/OBB
onready var flash = $MenuVR/Viewport/MainMenuVR/Flash/AnimationPlayer
onready var gf = $Girlfriend

var song_list = UserData.get_song_list("fnfvr")

var states = []
var sounds = []
var cur_state = 0

# Story mode variables
var week_idx = 0
var story_difficulty_idx = 1

# Freeplay variables
var freeplay_list = UserData.get_freeplay_list("fnfvr")
var freeplay_pitch_scale = 1
var freeplay_song_idx = 0
var freeplay_difficulty_idx = 1

func _ready():
	Conductor.set_pitch_scale()
	Conductor.volume_db = linear2db(0.7)
	Conductor.play_music(FREAKY_MENU, 102)
	
	for i in len(state_paths):
		var state = get_node(state_paths[i])
		
		if i == cur_state:
			state.show()
		else:
			state.hide()
		
		states.append(state)
	
	for path in sound_paths:
		sounds.append(get_node(path))
	
	if cur_state == 0:
		Conductor.connect("quarter_hit", self, "_on_quarter_hit", [], CONNECT_ONESHOT)
		main.player.play_transition("RESET")
	else:
		main.player.play_transition("Basic_Fade_In")

func change_state(state: int, sound: int = -1):
	# INTRO SPECIAL CASE
	if cur_state == 0 && Conductor.get_quarter(true) < 16 && Conductor.is_connected("quarter_hit", self, "_on_quarter_hit"):
		Conductor.disconnect("quarter_hit", self, "_on_quarter_hit")
	
	cur_state = state
	
	for i in len(states):
		if i == cur_state:
			states[i].show()
		else:
			states[i].hide()
	
	if sound > -1:
		sounds[sound].play()
	
	flash.play("Flash")

func _on_quarter_hit(quarter):
	if cur_state == 0:
		if quarter == 16:
			change_state(1)
			return
		
		var intro_anim = states[0].get_node("AnimationPlayer")
		var anim_name = str(quarter)
		
		if intro_anim.has_animation(anim_name):
			intro_anim.play(anim_name)
		
		Conductor.call_deferred("connect", "quarter_hit", self, "_on_quarter_hit", [], CONNECT_ONESHOT)

func _switch_to_story_mode(_trans_name):
	var level_manager_args = {
			"difficulty": story_difficulty_idx,
			"prev_state_variables": {
				"week_idx": week_idx,
				"story_difficulty_idx": story_difficulty_idx,
				"cur_state": 3
			}
		}
	
	get_parent().switch_state(song_list.weeks[week_idx].level_manager_path, level_manager_args)

func _switch_to_freeplay(_trans_name):
	var song_data: SongData = freeplay_list[freeplay_song_idx]
	
	var level_manager_args = {
		"state_stack": [
			song_data
		],
		"state_args": [
			{}
		],
		"difficulty": freeplay_difficulty_idx,
		"is_freeplay": true,
		"prev_state_variables": {
			"cur_state": 4,
			"freeplay_pitch_scale": freeplay_pitch_scale,
			"freeplay_song_idx": freeplay_song_idx,
			"freeplay_difficulty_idx": freeplay_difficulty_idx
		}
	}
	
	Conductor.set_pitch_scale(freeplay_pitch_scale)
	
	get_parent().switch_state(LEVEL_MANAGER, level_manager_args)
