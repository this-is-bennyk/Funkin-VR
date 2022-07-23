extends Control

onready var main = get_tree().root.get_node("Main")
# What the fuck
onready var main_menu = get_parent().get_parent().get_parent().get_parent()

onready var week_thumbnail = $Week_Thumbnails
onready var week_logos = $Week_Logos
onready var week_name_display = $Week_Name
onready var week_score_display = $Week_Score
onready var week_tracklist_display = $Week_Tracklist
onready var week_difficulty_display = $Cur_Difficulty
onready var week_difficulty_tween = $Cur_Difficulty/Tween
onready var prev_difficulty_btn = $Prev_Difficulty
onready var next_difficulty_btn = $Next_Difficulty

func _ready():
	call_deferred("change_week_info")

func _on_option_changed(increment):
	var prev_difficulties = week_difficulty_display.frames
	var prev_num_difficulties = len(week_difficulty_display.frames.animations)
	
	main_menu.week_idx = wrapi(main_menu.week_idx + increment, 0, len(main_menu.song_list.weeks))
	change_week_info()
	
	var cur_difficulties = week_difficulty_display.frames
	var cur_num_difficulties = len(week_difficulty_display.frames.animations)
	
	if cur_difficulties != prev_difficulties:
		_tween_difficulty()
	
	if cur_num_difficulties < prev_num_difficulties:
		main_menu.story_difficulty_idx = clamp(main_menu.story_difficulty_idx, 0, cur_num_difficulties - 1)
	elif cur_num_difficulties > prev_num_difficulties:
		main_menu.story_difficulty_idx = int(cur_num_difficulties / 2.0)
	# Otherwise the index stays the same (since the player prolly wants the same difficulty)
	
	main_menu.sounds[0].play()

func _on_week_selection_confirmed():
	main_menu.gui_obb.disabled = true
	
	Conductor.stop_song()
	main_menu.sounds[1].play()
	main_menu.gf.play_anim("Cheer", 99)
	
	var timer = get_tree().create_timer(1)
	
	timer.connect("timeout", main.player, "play_transition", ["Basic_Fade_Out"], CONNECT_DEFERRED | CONNECT_ONESHOT)
	timer.connect("timeout", main.player, "connect", ["transition_finished", main_menu, "_switch_to_story_mode", [], CONNECT_DEFERRED | CONNECT_ONESHOT], CONNECT_DEFERRED | CONNECT_ONESHOT)

func _on_difficulty_changed(increment):
	main_menu.story_difficulty_idx = wrapi(main_menu.story_difficulty_idx + increment, 0, len(week_difficulty_display.frames.animations))
	
	change_week_info()
	_tween_difficulty()

func change_week_info():
	var week = main_menu.song_list.weeks[main_menu.week_idx]
	var score = 0
	
	week_thumbnail.frame = main_menu.week_idx
	week_logos.frame = main_menu.week_idx
	week_name_display.text = week.week_name
	week_tracklist_display.text = "TRACKS:\n"
	week_score_display.text = "Score: "
	
	for song_data in week.song_datas:
		week_tracklist_display.text += song_data.name + "\n"
		score += UserData.get_song_score(song_data.name, song_data.difficulty_names[main_menu.story_difficulty_idx], "fnfvr")
	week_score_display.text += str(score)
	
	week_difficulty_display.frames = week.week_difficulties
	week_difficulty_display.play(str(main_menu.story_difficulty_idx))

func _tween_difficulty():
	week_difficulty_tween.stop_all()
	week_difficulty_tween.interpolate_property(week_difficulty_display, "offset:y", -15, 0, 0.07)
	week_difficulty_tween.interpolate_property(week_difficulty_display, "modulate:a", 0, 1, 0.07)
	week_difficulty_tween.start()
