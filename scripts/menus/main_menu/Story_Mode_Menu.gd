extends Menu3D

const CHAR_PATH = "res://assets/models/chars/"
const LVL_PATH = "res://prototypes/game/weeks/"
const LVL_RANGE = [1, 4]
const CHAR_POS = Vector3(0, 0, -3.5)

onready var week_num_display = $GUI/Viewport/Story_Mode_GUI/Title/ColorRect/Week_Number
onready var week_name_display = $GUI/Viewport/Story_Mode_GUI/Title/Week_Name
onready var week_info_display = $GUI/Viewport/Story_Mode_GUI/Title/Week_Info

onready var diff_bg_l1 = $GUI/Viewport/Story_Mode_GUI/Difficulty_BG_L0/Diff_BG_L1
onready var diff_bg_l2 = $GUI/Viewport/Story_Mode_GUI/Difficulty_BG_L0/Diff_BG_L2
onready var diff_bg_l3 = $GUI/Viewport/Story_Mode_GUI/Difficulty_BG_L0/Diff_BG_L3
onready var difficulty_display = $GUI/Viewport/Story_Mode_GUI/Difficulty_BG_L0/Difficulty

var cur_character = null

var week_idx = 1
var week_info = {}

var difficulty_idx = 1
var difficulty_info = [
	{
		l1 = "2edc00",
		l2 = "00b41f",
		l3 = "007737"
	},
	{
		l1 = "ffdf00",
		l2 = "ffb400",
		l3 = "ff8600"
	},
	{
		l1 = "ff4a00",
		l2 = "f51700",
		l3 = "cb1300"
	},
]

var characters = [
	null,
	preload("res://assets/models/chars/dad/Dad.tscn").instance(),
	preload("res://assets/models/chars/spooky_kids/Spooky_Kids.tscn").instance(),
	preload("res://assets/models/chars/pico/Pico.tscn").instance(),
	preload("res://assets/models/chars/mom/Mom.tscn").instance()
]

func _ready():
	menu_items = {
		$GUI/Back/Area: null,
		$GUI/Prev_Week/Area: null,
		$GUI/Next_Week/Area: null,
		$GUI/Prev_Diff/Area: null,
		$GUI/Next_Diff/Area: null,
		$GUI/Play/Area: null
	}
	
	var file = File.new()
	file.open("res://assets/data/week_info.json", File.READ)
	week_info = JSON.parse(file.get_as_text()).result
	
	change_week(0)
	change_difficulty(0)
	
	cur_character.start()
	
	Player.play_transition(Player.Transition.FADE_IN)

func do_menu_item_action():
	.do_menu_item_action()
	
	match cur_menu_item.name:
		"Back":
			return_to_main_menu()
		"Prev_Week":
			change_week(-1)
		"Next_Week":
			change_week(1)
		"Prev_Diff":
			change_difficulty(-1)
		"Next_Diff":
			change_difficulty(1)
		"Play":
			play_level()

func change_week(increment):
	if "LVL_RANGE" in self:
		week_idx = wrapi(week_idx + increment, LVL_RANGE[0], LVL_RANGE[1] + 1)
	else:
		week_idx = wrapi(week_idx + increment, 0, week_info.size())
	
	var cur_week_info = week_info[week_info.keys()[week_idx]]
	
	week_num_display.text = "WEEk " + str(week_idx)
	week_name_display.text = cur_week_info.week_name
	
	update_score(cur_week_info)
	
	if cur_character:
		cur_character.stop()
		remove_child(cur_character)
	cur_character = characters[week_idx]
	add_child(cur_character)
	
	cur_character.scale = Vector3(Player.MODEL_SCALE, Player.MODEL_SCALE, Player.MODEL_SCALE)
	cur_character.translation = CHAR_POS
	cur_character.start()

func change_difficulty(increment):
	difficulty_idx = wrapi(difficulty_idx + increment, 0, difficulty_info.size())
	
	diff_bg_l1.self_modulate = difficulty_info[difficulty_idx].l1
	diff_bg_l2.self_modulate = difficulty_info[difficulty_idx].l2
	diff_bg_l3.self_modulate = difficulty_info[difficulty_idx].l3
	
	difficulty_display.frame = difficulty_idx
	
	update_score(week_info[week_info.keys()[week_idx]])

func update_score(cur_week_info):
	for i in len(cur_week_info.tracks):
		if i == 0:
			week_info_display.text = "Tracks: "
		
		week_info_display.text += cur_week_info.tracks[i]
		
		if i != len(cur_week_info.tracks) - 1:
			week_info_display.text += ", "
	
	week_info_display.text += "\n"
	
	var score = 0
	
	var difficulty_suffix = ""
	match difficulty_idx:
		0:
			difficulty_suffix = "-easy"
		2:
			difficulty_suffix = "-hard"
	
	for track_filename in cur_week_info.track_filenames:
		if Settings.has_setting("fnf", track_filename + difficulty_suffix):
			score += Settings.get_setting("fnf", track_filename + difficulty_suffix)
	week_info_display.text += "Score: " + str(score)
#	week_info_display.text += " / With Modifiers: Coming soon!"

func play_level():
	set_process(false)
	
	Conductor.stop_song()
	
	get_tree().create_timer(0.8).connect("timeout", Player, "play_transition", [Player.Transition.FADE_OUT], CONNECT_ONESHOT)
	yield(get_tree().create_timer(1.3), "timeout")
	
	var difficulty_suffix = ""
	match difficulty_idx:
		0:
			difficulty_suffix = "-easy"
		2:
			difficulty_suffix = "-hard"
	
	get_parent().load_scene(LVL_PATH + week_info[week_info.keys()[week_idx]].week_filename + ".tscn", {"difficulty": difficulty_suffix})
