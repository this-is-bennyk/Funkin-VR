extends Control

export(Array, NodePath) var button_paths

onready var main = get_tree().root.get_node("Main")
# What the fuck
onready var main_menu = get_parent().get_parent().get_parent().get_parent().get_parent()

onready var song_select_menu = $Song_Select_Menu

onready var score_bg = $Score_BG
onready var score_fg = $Score_FG
onready var difficulty_name = $Difficulty

onready var song_speed_indicator = $Song_Speed_Indicator
onready var song_speed_changer = $Song_Speed_Changer
onready var botplay_button = $Botplay_Button

var song_score
var song_lerp_score = 0

func _ready():
	for button_path in button_paths:
		var button = get_node(button_path)
		
		var down_event = InputEventAction.new()
		var up_event = InputEventAction.new()
		
		down_event.action = button.name.to_lower()
		up_event.action = down_event.action
		
		down_event.pressed = true
		up_event.pressed = false
		
		button.connect("button_down", self, "_input", [down_event])
		button.connect("button_up", self, "_input", [up_event])
	
	# CORNER: the first song has only 1 difficulty
	var cur_num_difficulties = len(main_menu.freeplay_list[main_menu.freeplay_song_idx].difficulty_names)
	if cur_num_difficulties < 2:
		main_menu.freeplay_difficulty_idx = 0
	
	song_select_menu.get_node("Selection_Audio").volume_db = -80
	song_select_menu.options = []
	
	for song_data in main_menu.freeplay_list:
		song_select_menu.options.append(song_data.name)
	
	song_select_menu.on_ready(false)
	song_select_menu.get_node("Selection_Audio").volume_db = 0
	
	for idx in song_select_menu.options_container.get_child_count():
		var icon = AnimatedSprite.new()
		var option = song_select_menu.options_container.get_child(idx)
		
		icon.frames = main_menu.freeplay_list[idx].icons
		icon.frame = main_menu.freeplay_list[idx].icon_index
		
		option.add_child(icon)
		
		icon.position.x = option.rect_size.x + 75 + 20
		icon.position.y = 27.5
	
	song_select_menu.change_option_to(main_menu.freeplay_song_idx)
	
	change_song_stats()
	song_lerp_score = song_score
	
	song_speed_indicator.text = "Song Speed: " + str(Conductor.pitch_scale)
	song_speed_changer.value = main_menu.freeplay_pitch_scale
	
	botplay_button.pressed = Debug.botplay

func _process(delta):
	song_lerp_score = lerp(song_lerp_score, song_score, GodotX.get_haxeflixel_lerp(0.2))
	score_fg.text = String(round(song_lerp_score))
	score_bg.text = score_fg.text

func _input(event):
	if GodotX.xor(event.is_action_pressed("ui_left"), event.is_action_pressed("ui_right")):
		var increment = -1 if event.is_action_pressed("ui_left") else 1
		
		main_menu.freeplay_difficulty_idx = wrapi(main_menu.freeplay_difficulty_idx + increment, 0, len(main_menu.freeplay_list[main_menu.freeplay_song_idx].difficulty_names))
		change_song_stats()
	
	elif event.is_action_released("ui_cancel"):
		Debug.botplay = false
		botplay_button.pressed = false
		song_speed_changer.value = 1
		song_speed_indicator.text = "Song Speed: "
		
		main_menu.change_state(2, 2)
	
	else:
		song_select_menu.on_input(event)

func change_song_stats():
	var cur_song_data = main_menu.freeplay_list[main_menu.freeplay_song_idx]
	var cur_diff_name = cur_song_data.difficulty_names[main_menu.freeplay_difficulty_idx]
	
	song_score = UserData.get_song_score(cur_song_data.name, cur_diff_name, "fnfvr")
	difficulty_name.text = "< " + cur_diff_name + " >"

func _on_option_changed(option_idx, _option):
	var prev_num_difficulties = len(main_menu.freeplay_list[main_menu.freeplay_song_idx].difficulty_names)
	
	main_menu.freeplay_song_idx = option_idx
	
	var cur_num_difficulties = len(main_menu.freeplay_list[main_menu.freeplay_song_idx].difficulty_names)
	
	if cur_num_difficulties < prev_num_difficulties:
		main_menu.freeplay_difficulty_idx = clamp(main_menu.freeplay_difficulty_idx, 0, cur_num_difficulties - 1)
	elif cur_num_difficulties > prev_num_difficulties:
		main_menu.freeplay_difficulty_idx = int(main_menu.freeplay_cur_num_difficulties / 2.0)
	# Otherwise the index stays the same (since the player prolly wants the same difficulty)
	
	change_song_stats()

func _on_option_selected(_option_idx, _option):
	_disable_input()
	
	Conductor.stop_song()
	main_menu.sounds[1].play()
	main_menu.gf.play_anim("Cheer", 99)
	
	var timer = get_tree().create_timer(1)
	
	timer.connect("timeout", main.player, "play_transition", ["Basic_Fade_Out"], CONNECT_DEFERRED | CONNECT_ONESHOT)
	timer.connect("timeout", main.player, "connect", ["transition_finished", main_menu, "_switch_to_freeplay", [], CONNECT_DEFERRED | CONNECT_ONESHOT], CONNECT_DEFERRED | CONNECT_ONESHOT)

func _disable_input():
	main_menu.gui_obb.disabled = true
	
	set_process(false)
	set_process_input(false)
	
	song_select_menu.disable_input()
	song_select_menu.disconnect("option_changed", self, "_on_option_changed")
	
	song_speed_changer.editable = false
	
	botplay_button.disabled = true

func _on_song_speed_changed(value: float):
	main_menu.freeplay_pitch_scale = value
	song_speed_indicator.text = "Song Speed: " + str(value)

func _on_botplay_toggled(pressed: bool):
	Debug.botplay = pressed
