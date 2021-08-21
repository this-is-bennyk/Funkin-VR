extends Menu3D

const LVL_PATH = "res://prototypes/game/weeks/"
const ICONS = preload("res://assets/graphics/game/hud/icons/character_icons.tres")

onready var double_prev_song_display = $Freeplay_VP/Freeplay_Mode_GUI/Double_Prev_Song
onready var prev_song_display = $Freeplay_VP/Freeplay_Mode_GUI/Prev_Song
onready var cur_song_display = $Freeplay_VP/Freeplay_Mode_GUI/Cur_Song
onready var next_song_display = $Freeplay_VP/Freeplay_Mode_GUI/Next_Song
onready var double_next_song_display = $Freeplay_VP/Freeplay_Mode_GUI/Double_Next_Song
onready var song_list_anim_player = $Freeplay_VP/Freeplay_Mode_GUI/Song_List_AnimPlayer

onready var char_name_display = $Freeplay_VP/Freeplay_Mode_GUI/Title/Char_Name
onready var week_info_display = $Freeplay_VP/Freeplay_Mode_GUI/Title/Week_Info

onready var diff_bg_l1 = $Freeplay_VP/Freeplay_Mode_GUI/Difficulty_BG_L0/Diff_BG_L1
onready var diff_bg_l2 = $Freeplay_VP/Freeplay_Mode_GUI/Difficulty_BG_L0/Diff_BG_L2
onready var diff_bg_l3 = $Freeplay_VP/Freeplay_Mode_GUI/Difficulty_BG_L0/Diff_BG_L3
onready var difficulty_display = $Freeplay_VP/Freeplay_Mode_GUI/Difficulty_BG_L0/Difficulty

onready var inst_player = $Inst_Player
onready var inst_anim = $Inst_Player_Anim

var freeplay_list = {}

var song_idx = 0
var song_list = []
var icon_idx_list = []
var char_name_list = []

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

func _ready():
	menu_items = {
		$Back/Area: null,
		$Prev_Song/Area: null,
		$Next_Song/Area: null,
		$Prev_Diff/Area: null,
		$Next_Diff/Area: null,
		$Play/Area: null
	}
	
	var file = File.new()
	file.open("res://assets/data/freeplay_list.json", File.READ)
	freeplay_list = JSON.parse(file.get_as_text()).result
	
	for song_name in freeplay_list:
		var category = freeplay_list[song_name].category if freeplay_list[song_name].has("category") else "fnf"
		var extension = freeplay_list[song_name].extension if freeplay_list[song_name].has("extension") else "ogg"
		var chart_type = SongChart.ChartType.SNIFF
		
		if freeplay_list[song_name].has("chart_type"):
			if freeplay_list[song_name].chart_type == 1:
				chart_type = SongChart.ChartType.FNFVR
#			match freeplay_list[song_name].chart_type:
#				1:
#					print("here")
#					chart_type = SongChart.ChartType.FNFVR
		
		song_list.append(SongChart.new(song_name, "", category, extension, chart_type))
		icon_idx_list.append(freeplay_list[song_name].icon_idx)
		char_name_list.append(freeplay_list[song_name].char_name)
	
	change_song(0)
	change_difficulty(0)
	
	Player.play_transition(Player.Transition.FADE_IN)

func _process(delta):
	if !inst_player.playing:
		inst_player.play()
	
#	if Input.is_action_just_pressed("ui_left"):
#		change_song(-1)
#	elif Input.is_action_just_pressed("ui_right"):
#		change_song(1)

func do_menu_item_action():
	.do_menu_item_action()
	
	match cur_menu_item.name:
		"Back":
			return_to_main_menu()
		"Prev_Song":
			change_song(-1)
		"Next_Song":
			change_song(1)
		"Prev_Diff":
			change_difficulty(-1)
		"Next_Diff":
			change_difficulty(1)
		"Play":
			play_level()

func change_song(increment):
	song_idx = wrapi(song_idx + increment, 0, len(song_list))
	
	var anim_name = "Default"
	
	var three_behind_idx = wrapi(song_idx - 3, 0, len(song_list))
	var two_behind_idx = wrapi(song_idx - 2, 0, len(song_list))
	var one_behind_idx = wrapi(song_idx - 1, 0, len(song_list))
	var one_ahead_idx = wrapi(song_idx + 1, 0, len(song_list))
	var two_ahead_idx = wrapi(song_idx + 2, 0, len(song_list))
	var three_ahead_idx = wrapi(song_idx + 3, 0, len(song_list))
	
	var double_prev_idx = two_behind_idx
	var prev_idx = one_behind_idx
	var cur_idx = song_idx
	var next_idx = one_ahead_idx
	var double_next_idx = two_ahead_idx
	
	if increment == 1:
		double_prev_idx = three_behind_idx
		prev_idx = two_behind_idx
		cur_idx = one_behind_idx
		next_idx = song_idx
		double_next_idx = one_ahead_idx
		anim_name = "Next"
	elif increment == -1:
		double_prev_idx = one_behind_idx
		prev_idx = song_idx
		cur_idx = one_ahead_idx
		next_idx = two_ahead_idx
		double_next_idx = three_ahead_idx
		anim_name = "Prev"
	
	double_prev_song_display.texture = ICONS.get_frame("default", icon_idx_list[double_prev_idx])
	double_prev_song_display.get_node("Label").text = get_song_name(double_prev_idx)

	var prev_idx_inc = 2 if increment == -1 else 0
	prev_song_display.texture = ICONS.get_frame("default", icon_idx_list[prev_idx] + prev_idx_inc)
	prev_song_display.get_node("Label").text = get_song_name(prev_idx)
	
	var cur_idx_inc = 2 if increment == 0 else 0
	cur_song_display.texture = ICONS.get_frame("default", icon_idx_list[cur_idx] + cur_idx_inc)
	cur_song_display.get_node("Label").text = get_song_name(cur_idx)
	
	var next_idx_inc = 2 if increment == 1 else 0
	next_song_display.texture = ICONS.get_frame("default", icon_idx_list[next_idx] + next_idx_inc)
	next_song_display.get_node("Label").text = get_song_name(next_idx)

	double_next_song_display.texture = ICONS.get_frame("default", icon_idx_list[double_next_idx])
	double_next_song_display.get_node("Label").text = get_song_name(double_next_idx)

	song_list_anim_player.stop()
	song_list_anim_player.play(anim_name)
	
	inst_player.stop()
	inst_player.stream = song_list[song_idx].song
	inst_player.play()
	
	inst_anim.stop()
	inst_anim.play("Fade_In")
	
	char_name_display.text = char_name_list[song_idx]
	
	update_score(song_list[song_idx].json_name)

func get_song_name(idx):
	return freeplay_list[freeplay_list.keys()[idx]].corrected_name if \
		   freeplay_list[freeplay_list.keys()[idx]].has("corrected_name") else \
		   song_list[idx].song_name.capitalize()

func change_difficulty(increment):
	difficulty_idx = wrapi(difficulty_idx + increment, 0, difficulty_info.size())
	
	diff_bg_l1.self_modulate = difficulty_info[difficulty_idx].l1
	diff_bg_l2.self_modulate = difficulty_info[difficulty_idx].l2
	diff_bg_l3.self_modulate = difficulty_info[difficulty_idx].l3
	
	difficulty_display.frame = difficulty_idx
	
	update_score(song_list[song_idx].json_name)

func update_score(track_filename):
	var score = 0
	
	var difficulty_suffix = ""
	match difficulty_idx:
		0:
			difficulty_suffix = "-easy"
		2:
			difficulty_suffix = "-hard"
	
	if Settings.has_setting(song_list[song_idx].category, track_filename + difficulty_suffix):
		score = Settings.get_setting(song_list[song_idx].category, track_filename + difficulty_suffix)
	
	if week_info_display:
		week_info_display.text = "Score: " + str(score)
	else:
		$Freeplay_VP/Freeplay_Mode_GUI/Title/Week_Info.text = "Score: " + str(score)
#	week_info_display.text += " / With Modifiers: Coming soon!"

func play_level():
	set_process(false)
	
	inst_player.stop()
	
	get_tree().create_timer(0.8).connect("timeout", Player, "play_transition", [Player.Transition.FADE_OUT], CONNECT_ONESHOT)
	yield(get_tree().create_timer(1.3), "timeout")
	
	var difficulty_suffix = ""
	match difficulty_idx:
		0:
			difficulty_suffix = "-easy"
		2:
			difficulty_suffix = "-hard"
	
	var cur_song = song_list[song_idx]
	
	get_parent().load_scene(LVL_PATH + freeplay_list[freeplay_list.keys()[song_idx]].week_filename + ".tscn", 
							{
								"song_json_names": [cur_song.json_name],
								"difficulty": difficulty_suffix,
								"category": cur_song.category,
								"extensions": [cur_song.extension],
								"chart_type": cur_song.chart_type,
								"is_freeplay": true
							})
