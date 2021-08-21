class_name Level
extends Spatial

enum LevelState {START, ADVANCING, END}

const HEALTH_BOOST = 0.023
const HEALTH_PENALTY_OVERTAP = -0.04
const HEALTH_PENALTY_MISS = -0.0475

# The previous two values are extremely confusing in the Funkin' source, so lemme explain:

# HEALTH_PENALTY_OVERTAP: for when you tap on an empty space rather than a note.
#					    - This could be between notes or in the stretches of time between player sections (no ghost tapping).
#					    - Does not apply if you are already holding down the direction from a previous note.
#					    - The vocals mute and the record scratch plays when applying an overtap penalty.

# HEALTH_PENALTY_MISS: for when the note has passed beyond the safe zone of its strum time.
#					    - Also applies when missing the sustained part of a sustained note.
#					    - The vocals mute when applying a miss penalty.

# Also BF gets stunned for 5 seconds after the overtap penalty??? wtf i'm not doing that

const COMBO_NUM_INIT_SCALE = 0.425
const COMBO_NUM_FINAL_SCALE = 0.375

const SCORE_NUM_INIT_SCALE = 0.3 * (0.425 / 0.375)
const SCORE_NUM_FINAL_SCALE = 0.3

signal advance_state

export(bool) var has_multiple_onetime_events = false

# ---------- Characters ----------

var opponent
var metronome

# ---------- Step Zone ----------

onready var player_step_zone = $Player_Step_Zone
onready var opponent_step_zone = $Opponent_Step_Zone

onready var player_left_zone_anim = $Player_Step_Zone/Left/AnimationPlayer
onready var player_down_zone_anim = $Player_Step_Zone/Down/AnimationPlayer
onready var player_up_zone_anim = $Player_Step_Zone/Up/AnimationPlayer
onready var player_right_zone_anim = $Player_Step_Zone/Right/AnimationPlayer

onready var opponent_left_zone_anim = $Opponent_Step_Zone/Left/AnimationPlayer
onready var opponent_down_zone_anim = $Opponent_Step_Zone/Down/AnimationPlayer
onready var opponent_up_zone_anim = $Opponent_Step_Zone/Up/AnimationPlayer
onready var opponent_right_zone_anim = $Opponent_Step_Zone/Right/AnimationPlayer

# ---------- Countdown ----------

var countdown_voices = [
	preload("res://assets/sounds/introGo.ogg"),
	preload("res://assets/sounds/intro1.ogg"),
	preload("res://assets/sounds/intro2.ogg"),
	preload("res://assets/sounds/intro3.ogg")
]

onready var countdown = $Countdown_Messages/Countdown
onready var ready = $Countdown_Messages/Ready
onready var set = $Countdown_Messages/Set
onready var go = $Countdown_Messages/Go
onready var countdown_tween = $Countdown_Messages/Tween

# ---------- Songs + Notes ----------

var ratings = {
	sick = preload("res://prototypes/game/ratings/Sick_Rating.tscn"),
	good = preload("res://prototypes/game/ratings/Good_Rating.tscn"),
	bad = preload("res://prototypes/game/ratings/Bad_Rating.tscn"),
	shit = preload("res://prototypes/game/ratings/Shit_Rating.tscn")
}

var miss_sounds = [
	preload("res://assets/sounds/missnote1.ogg"),
	preload("res://assets/sounds/missnote2.ogg"),
	preload("res://assets/sounds/missnote3.ogg")
]

var songs = []
var song_json_names = []
var difficulty = "-hard"
var category = "fnf"
var extensions = ["ogg", "ogg", "ogg"]
var chart_type = SongChart.ChartType.SNIFF

var opponent_anim_sustains = [0, 0, 0, 0]

# ---------- Events ----------

"""
----- Event Formats -----

Onetime:
	[
		[
			time_to_happen (units),
			units_of_time (Conductor.Notes OR -1 for seconds),
			funcref (FuncRef),
			args (Array)
		],
		...
	]

BPM Changes:
	[
		[
			time_to_happen (seconds),
			funcref (FuncRef to Conductor function),
			BPM (Array of 1 number)
		],
		...
	]

Repeating:
	[
		[
			initial_time_to_happen (units),
			increment_time (units),
			units_of_time (Conductor.Notes OR -1 for seconds),
			funcref (FuncRef),
			args (Array)
		],
		...
	]

Random:
	[
		[
			initial_time_to_happen (units),
			increment_time_range (Array (size 2) of numbers in units),
			units_of_time (Conductor.Notes OR -1 for seconds),
			funcref (FuncRef),
			args (Array)
		],
		...
	]

"""
var onetime_events = []
var bpm_change_events = []
var repeating_events = []
var random_events = []

var async_event_func_names = []

# ---------- Stats ----------

onready var player_health_bar = $HUD/Health_Bar/Player_Bar
onready var player_icon = $HUD/Health_Bar/Icons/Player_Icon

onready var opponent_health_bar = $HUD/Health_Bar/Opponent_Bar
onready var opponent_icon = $HUD/Health_Bar/Icons/Opponent_Icon

onready var health_icons_pos = $HUD/Health_Bar/Icons

onready var combo_number = {
	hundreds = $HUD/Combo/Hundreds,
	tens = $HUD/Combo/Tens,
	ones = $HUD/Combo/Ones,
	tween = $HUD/Combo/Tween
}

onready var max_combo_number = {
	hundreds = $HUD/Max_Combo/Hundreds,
	tens = $HUD/Max_Combo/Tens,
	ones = $HUD/Max_Combo/Ones,
	tween = $HUD/Max_Combo/Tween
}

onready var score_number = {
	hundred_thousands = $HUD/Score/Hundred_Thousands,
	ten_thousands = $HUD/Score/Ten_Thousands,
	thousands = $HUD/Score/Thousands,
	hundreds = $HUD/Score/Hundreds,
	tens = $HUD/Score/Tens,
	ones = $HUD/Score/Ones,
	tween = $HUD/Score/Tween
}

var health = 1 # Range: 0 - 2
var combo = 0 # Shits end combo, missing sustains doesn't
var max_combo = 0
var score = 0
var dying = false
var has_died = false
var is_freeplay = false

var player_icons_idx = 0
var opponent_icons_idx = 10

var score_list = {}

# ---------- Level Generation ----------

func _ready():
	Conductor.connect("finished", self, "on_conductor_song_finished")
	set_video_driver_stuff()
	set_songs()
	on_ready()

func set_songs():
	pass

# In inherited levels, any onready vars must be changed either here or when 
# the levels needs to change them
func on_ready():
	set_process(false)
	
	for i in 5:
		yield(get_tree(), "idle_frame")
	
	call_deferred("play_level", LevelState.START)

# For turning on / off certain things depending on the video driver
func set_video_driver_stuff():
	pass

func play_level(lvl_state):
	match lvl_state:
		LevelState.START:
			Player.play_transition(Player.Transition.FADE_IN)
			
			for i in len(song_json_names):
				songs.append(SongChart.new(song_json_names[i], difficulty, category, extensions[i], chart_type))
				score_list[song_json_names[i] + difficulty] = 0
			
			play_level(LevelState.ADVANCING)
		
		LevelState.ADVANCING:
			Player.can_pause = false
			set_process(false)
			clear_event_signals()
			
			# TODO: Right now we're assuming that there will be no notes in the step zones
			# when a song is finished. This should be true in all cases, but you never know.
			if !songs.empty():
				opponent.stop()
				metronome.stop()
				
				dying = false
				
				if !has_died:
					do_pre_level_event()
				do_level_prep()
				
				update_health(1, true)
				update_number_stat("combo", combo_number, 0, true) # Shits end combo, missing sustains doesn't
				update_number_stat("max_combo", max_combo_number, 0, true)
				update_number_stat("score", score_number, 0, true)
				
				var cur_chart = songs[0]
				
				print("")
				
				player_step_zone.clear_notes()
				player_step_zone.generate_notes(cur_chart)
				
				opponent_step_zone.clear_notes()
				opponent_step_zone.generate_notes(cur_chart)
				
				if cur_chart.needs_vocals:
					Conductor.play_song_with_countdown(cur_chart.song, cur_chart.bpm, cur_chart.vocals, cur_chart.speed)
				else:
					Conductor.play_song_with_countdown(cur_chart.song, cur_chart.bpm, null, cur_chart.speed)
				
				opponent.start()
				metronome.start()
				
				set_process(true)
				yield(do_countdown(), "completed")
				
				Player.can_pause = true
				connect("advance_state", self, "play_level", [LevelState.ADVANCING], CONNECT_ONESHOT)
			else:
				do_ender_event()
				do_level_cleanup()
				
				for key in score_list:
					if score_list[key] > Settings.get_setting(category, key):
						Settings.set_setting(category, key, score_list[key])
				Settings.save_settings()
				
				if get_parent().name == "Main":
					var scene = "res://prototypes/menus/main_menu/Freeplay_Mode_Menu.tscn" if is_freeplay else "res://prototypes/menus/main_menu/Story_Mode_Menu.tscn"
					
					Player.play_transition(Player.Transition.FADE_OUT)
					get_tree().create_timer(0.5).connect("timeout", get_parent(), "load_scene", ["res://prototypes/menus/main_menu/Main_Menu.tscn"], CONNECT_ONESHOT)
#					Player.screen_anim.connect("animation_finished", get_parent(), "load_scene", [scene])
#					yield(Player.screen_anim, "animation_finished")
#
#					get_parent().load_scene("res://prototypes/menus/main_menu/Main_Menu.tscn")

func clear_event_signals(certain_events = null):
	if async_event_func_names.empty() || !certain_events:
		return
	
	var events_to_clear = certain_events if certain_events else async_event_func_names
	var incoming_connections = get_incoming_connections()
	
	for connection in incoming_connections:
		if connection.method_name in events_to_clear:
			connection.source.disconnect(connection.signal_name, self, connection.method_name)

func do_pre_level_event():
	pass

func do_level_prep():
	pass

func do_countdown():
	var countdown_co = yield(Conductor, "quarter_hit")
		
	while countdown_co < 0:
		countdown.stop()
		countdown.stream = countdown_voices[abs(countdown_co) - 1]
		countdown.play()
		
		if countdown_co == -3:
			countdown_tween.interpolate_property(ready, "opacity", 1, 0, Conductor.get_seconds_per_beat(), Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
			countdown_tween.start()
			
		elif countdown_co == -2:
			countdown_tween.interpolate_property(set, "opacity", 1, 0, Conductor.get_seconds_per_beat(), Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
			countdown_tween.start()
			
		elif countdown_co == -1:
			countdown_tween.interpolate_property(go, "opacity", 1, 0, Conductor.get_seconds_per_beat(), Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
			countdown_tween.start()
		
		countdown_co = yield(Conductor, "quarter_hit")

func do_ender_event():
	pass

func do_level_cleanup():
	pass

func generate_bpm_changes():
	bpm_change_events = []
	
	var cumulative_section_time = 0
	var cur_bpm = songs[0].bpm
	
	for section in songs[0].sections:
		if section.has("changeBPM") && section["changeBPM"]:
			bpm_change_events.append([cumulative_section_time,
									  funcref(Conductor, "change_bpm"),
									  [section["bpm"]]])
			cur_bpm = section["bpm"]
		
		cumulative_section_time += 60.0 / cur_bpm * section["lengthInSteps"] / 4.0
#		cumulative_section_time += 60.0 / cur_bpm * 4.0

# Game Processing

func _process(delta):
	on_update(delta)

func on_update(delta):
	player_step_zone.update(delta)
	opponent_step_zone.update(delta)
	
	if !dying:
		update_onetime_events()
		update_bpm_change_events()
		update_repeating_events()
		update_random_events()
		
		update_opposing_zone_anims(delta)
	
#	if get_node_or_null("Left_Inner"):
#		$Left_Inner.visible = GDScriptX.xor(Player.left_hand_aabb.intersects(player_step_zone.lanes[0].hitbox),
#											Player.right_hand_aabb.intersects(player_step_zone.lanes[0].hitbox))
#		$Down_Inner.visible = GDScriptX.xor(Player.left_hand_aabb.intersects(player_step_zone.lanes[1].hitbox),
#											Player.right_hand_aabb.intersects(player_step_zone.lanes[1].hitbox))
#		$Up_Inner.visible = GDScriptX.xor(Player.left_hand_aabb.intersects(player_step_zone.lanes[2].hitbox),
#										  Player.right_hand_aabb.intersects(player_step_zone.lanes[2].hitbox))
#		$Right_Inner.visible = GDScriptX.xor(Player.left_hand_aabb.intersects(player_step_zone.lanes[3].hitbox),
#											 Player.right_hand_aabb.intersects(player_step_zone.lanes[3].hitbox))

func update_health(increment, resetting = false):
	if resetting:
		health = increment
	else:
		health = clamp(health + increment, 0, 2)
	
	var health_percent = health / 2.0
	
	# Defaults to state where player has >= 80% health
	var player_health_state = 4
	var opponent_health_state = 0
	
	if health_percent < 0.2:
		player_health_state = 0
		opponent_health_state = 4
		
	elif health_percent >= 0.2 && health_percent < 0.4:
		player_health_state = 1
		opponent_health_state = 3
		
	elif health_percent >= 0.4 && health_percent < 0.6:
		player_health_state = 2
		opponent_health_state = 2
	
	elif health_percent >= 0.6 && health_percent < 0.8:
		player_health_state = 3
		opponent_health_state = 1
	
	player_icon.frame = player_icons_idx + player_health_state
	opponent_icon.frame = opponent_icons_idx + opponent_health_state
	
	player_health_bar.scale.y = health_percent
	opponent_health_bar.scale.y = 1 - health_percent
	
	health_icons_pos.translation.x = lerp(-1.225, 1.225, 1 - health_percent)
	
	if health == 0 && !Player.DEBUG:
		dying = true
		set_process(false)
		Player.can_pause = false
		# See if this fixes bug that advances to next song
		call_deferred("die", true)
#		die()

func update_number_stat(stat_name, stat_dict, increment, resetting = false):
	if resetting:
		set(stat_name, increment)
	else:
		set(stat_name, get(stat_name) + increment)
	
	var cur_stat_val = get(stat_name)
	var is_score = (stat_name == "score")
	
	var init_scale = Vector3(SCORE_NUM_FINAL_SCALE, SCORE_NUM_INIT_SCALE, 1) if is_score else Vector3(COMBO_NUM_FINAL_SCALE, COMBO_NUM_INIT_SCALE, 1)
	var final_scale = Vector3(SCORE_NUM_FINAL_SCALE, SCORE_NUM_FINAL_SCALE, 1) if is_score else Vector3(COMBO_NUM_FINAL_SCALE, COMBO_NUM_FINAL_SCALE, 1)
	
	if stat_name == "score":
		stat_dict.hundred_thousands.frame = int(cur_stat_val / 100_000.0) % 10
		stat_dict.ten_thousands.frame = int(cur_stat_val / 10_000.0) % 10
		stat_dict.thousands.frame = int(cur_stat_val / 1000.0) % 10
	
	stat_dict.hundreds.frame = int(cur_stat_val / 100.0) % 10
	stat_dict.tens.frame = int(cur_stat_val / 10.0) % 10
	stat_dict.ones.frame = cur_stat_val % 10
	
	stat_dict.tween.stop_all()
	
	for key in stat_dict:
		if stat_dict[key] is Tween:
			continue
		
		var num_condition = 0
		match stat_dict[key].name:
			"Hundred_Thousands":
				num_condition = 99999
			"Ten_Thousands":
				num_condition = 9999
			"Thousands":
				num_condition = 999
			"Hundreds":
				num_condition = 99
			"Tens":
				num_condition = 9
		
		if cur_stat_val > num_condition:
			stat_dict[key].opacity = 1
			stat_dict.tween.interpolate_property(stat_dict[key], "scale",
												 init_scale, final_scale,
												 2 / 24.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
			stat_dict.tween.interpolate_property(stat_dict[key], "translation:z",
												 0.15, 0,
												 2 / 24.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
			stat_dict.tween.start()
		else:
			stat_dict[key].opacity = 0.25
			stat_dict[key].scale = final_scale
			stat_dict[key].translation.z = 0

func update_onetime_events():
	if len(onetime_events) == 0:
		return
	
	if has_multiple_onetime_events:
		var events_to_delete = []
		
		for i in len(onetime_events):
			var event = onetime_events[i]
			
			var time_to_happen = event[0]
			var units = event[1]
			var time = get_event_time(units, false)
			
			if time >= time_to_happen:
				var result = event[2].call_funcv(event[3])
				events_to_delete.append(i)
		
		events_to_delete.invert()
		for idx in events_to_delete:
			onetime_events.remove(idx)
		
	else:
		var cur_event = onetime_events[0]
		
		var time_to_happen = cur_event[0]
		var units = cur_event[1]
		var time = get_event_time(units, false)
		
		if time >= time_to_happen:
			var result = cur_event[2].call_funcv(cur_event[3])
			onetime_events.pop_front()

func update_bpm_change_events():
	if len(bpm_change_events) == 0:
		return
	
	var cur_event = bpm_change_events[0]
	
	if Conductor.song_position >= cur_event[0]:
		var result = cur_event[1].call_funcv(cur_event[2])
		bpm_change_events.pop_front()

func update_repeating_events():
	if len(repeating_events) == 0:
		return
	
	for event in repeating_events:
		var time_to_happen = event[0]
		var units = event[2]

		var time = get_event_time(units, time_to_happen is int)
		
		if time >= time_to_happen:
			event[3].call_funcv(event[4])
			event[0] += event[1]

func update_random_events():
	if len(random_events) == 0:
		return
	
	for event in random_events:
		var time_to_happen = event[0]
		var units = event[2]
		var time_range = event[1]
		
		var time = get_event_time(units, time_to_happen is int)
		
		if time >= time_to_happen:
			event[3].call_funcv(event[4])
			event[0] += randi() % time_range[1] + time_range[0] if time_to_happen is int else rand_range(time_range[0], time_range[1])

func get_event_time(units, floored):
	match units:
		Conductor.Notes.QUARTER:
			return Conductor.get_quarter(floored)
		Conductor.Notes.EIGHTH:
			return Conductor.get_eighth(floored)
		Conductor.Notes.SIXTEENTH:
			return Conductor.get_sixteenth(floored)
		_:
			return Conductor.song_position

func update_opposing_zone_anims(delta):
	for i in opponent_anim_sustains.size():
		if opponent_anim_sustains[i] == 0:
			continue
		
		play_step_zone_anim(i, opponent_step_zone, "Confirm")
		
		opponent_anim_sustains[i] -= delta
		if opponent_anim_sustains[i] < 0:
			opponent_anim_sustains[i] = 0

func die(initial_call):
	if initial_call:
		clear_event_signals()
		
		player_step_zone.clear_notes()
		opponent_step_zone.clear_notes()
		
		Conductor.stop_song()
		hide()
		
		Player.connect("retry", self, "die", [false], CONNECT_ONESHOT)
		Player.call_deferred("do_game_over")
	else:
		has_died = true
		show()
		emit_signal("advance_state")

# Note Processing

func play_step_zone_anim(dir, step_zone, anim_name):
	match dir:
		Conductor.Directions.LEFT:
			var left_zone_anim = player_left_zone_anim if step_zone == player_step_zone else opponent_left_zone_anim
			left_zone_anim.stop()
			left_zone_anim.play(anim_name)
		
		Conductor.Directions.DOWN:
			var down_zone_anim = player_down_zone_anim if step_zone == player_step_zone else opponent_down_zone_anim
			down_zone_anim.stop()
			down_zone_anim.play(anim_name)
		
		Conductor.Directions.UP:
			var up_zone_anim = player_up_zone_anim if step_zone == player_step_zone else opponent_up_zone_anim
			up_zone_anim.stop()
			up_zone_anim.play(anim_name)
		
		Conductor.Directions.RIGHT:
			var right_zone_anim = player_right_zone_anim if step_zone == player_step_zone else opponent_right_zone_anim
			right_zone_anim.stop()
			right_zone_anim.play(anim_name)

# State Connections

func on_note_ready_to_hit(dir, sustain_length = 0):
#	print("dir: " + str(dir) + ", sustain_length: " + str(sustain_length))
	player_step_zone.lanes[dir].just_pressed_buffer = Conductor.SAFE_ZONE * 4.5 + sustain_length

func on_note_good_hit(dir, note_diff, global_origin):
	play_step_zone_anim(dir, player_step_zone, "Confirm")
	update_health(HEALTH_BOOST)
	
	var combo_increment = 1
	var score_increment = 350
	var rating = ratings.sick
	
	if note_diff > Conductor.SAFE_ZONE * 0.9:
		combo_increment = 0
		score_increment = 50
		rating = ratings.shit
		
	elif note_diff > Conductor.SAFE_ZONE * 0.75:
		score_increment = 100
		rating = ratings.bad
		
	elif note_diff > Conductor.SAFE_ZONE * 0.2:
		score_increment = 200
		rating = ratings.good
		
	update_number_stat("combo", combo_number, combo_increment, !bool(combo_increment))
	update_number_stat("score", score_number, score_increment)
	
	if combo > max_combo:
		update_number_stat("max_combo", max_combo_number, combo, true)
	
	var rating_inst = rating.instance()
	player_step_zone.add_child(rating_inst)
	rating_inst.global_transform = Transform(Basis().scaled(Vector3(0.1, 0.1, 0.1)), Vector3(global_origin.x, global_origin.y + 0.1, player_step_zone.global_transform.origin.z + 0.05))
	
	# The note has to have been hit by one of the hands, so we only need to check this condition I believe
	Player.set_rumble(dir in player_step_zone.zones_right_hand_in, Player.NOTE_RUMBLE)
	Conductor.vocals.volume_db = 0
	player_step_zone.miss_sound_player.stop()

func on_note_miss():
	if Player.DEBUG:
		return
	
	update_number_stat("combo", combo_number, 0, true)
	update_health(HEALTH_PENALTY_MISS)
	
	if !Player.DEBUG:
		Conductor.vocals.volume_db = -80

func on_sustain_part_hit(dir, delta):
	play_step_zone_anim(dir, player_step_zone, "Confirm")
	update_health(HEALTH_BOOST * delta)
	
	Player.set_rumble(dir in player_step_zone.zones_right_hand_in, Player.SUSTAIN_RUMBLE)
	Conductor.vocals.volume_db = 0
	player_step_zone.miss_sound_player.stop()

func on_sustain_part_miss(delta):
	if Player.DEBUG:
		return
	
	update_health(HEALTH_PENALTY_MISS * delta)
	
	if !Player.DEBUG:
		Conductor.vocals.volume_db = -80

func on_overtap():
#	update_health(HEALTH_PENALTY_OVERTAP)
#	Conductor.vocals.volume_db = -80
#
#	player_step_zone.miss_sound_player.stop()
#	player_step_zone.miss_sound_player.stream = miss_sounds[randi() % len(miss_sounds)]
#	player_step_zone.miss_sound_player.play()
	pass

func on_opponent_hit(dir, sustain_length):
	opponent.play_anim(dir, sustain_length)
	play_step_zone_anim(dir, opponent_step_zone, "Confirm")
	opponent_anim_sustains[dir] = sustain_length
	
	Conductor.vocals.volume_db = 0

func on_conductor_song_finished():
	if !dying:
		score_list[songs[0].json_name + difficulty] = score
		songs.pop_front()
		has_died = false
		emit_signal("advance_state")
