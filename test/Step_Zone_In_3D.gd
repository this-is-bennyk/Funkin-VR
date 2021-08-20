extends Spatial
#
#var note_mats = {
#	Conductor.Directions.LEFT: {
#		inner = preload("res://assets/models/note/materials/Left_Note_Inner.tres"),
#		outer = preload("res://assets/models/note/materials/Left_Note_Outer.tres"),
#		color = Color("#ff83ff")
#	},
#	Conductor.Directions.DOWN: {
#		inner = preload("res://assets/models/note/materials/Down_Note_Inner.tres"),
#		outer = preload("res://assets/models/note/materials/Down_Note_Outer.tres"),
#		color = Color("#22ffff")
#	},
#	Conductor.Directions.UP: {
#		inner = preload("res://assets/models/note/materials/Up_Note_Inner.tres"),
#		outer = preload("res://assets/models/note/materials/Up_Note_Outer.tres"),
#		color = Color("#2eff49")
#	},
#	Conductor.Directions.RIGHT: {
#		inner = preload("res://assets/models/note/materials/Right_Note_Inner.tres"),
#		outer = preload("res://assets/models/note/materials/Right_Note_Outer.tres"),
#		color = Color("#ff6288")
#	}
#}
#
#onready var player_step_zone = $Player_Step_Zone
#onready var opponent_step_zone = $Opponent_Step_Zone
#
#onready var player_left_zone_anim = $Player_Step_Zone/Left/AnimationPlayer
#onready var player_down_zone_anim = $Player_Step_Zone/Down/AnimationPlayer
#onready var player_up_zone_anim = $Player_Step_Zone/Up/AnimationPlayer
#onready var player_right_zone_anim = $Player_Step_Zone/Right/AnimationPlayer
#
#onready var opponent_left_zone_anim = $Opponent_Step_Zone/Left/AnimationPlayer
#onready var opponent_down_zone_anim = $Opponent_Step_Zone/Down/AnimationPlayer
#onready var opponent_up_zone_anim = $Opponent_Step_Zone/Up/AnimationPlayer
#onready var opponent_right_zone_anim = $Opponent_Step_Zone/Right/AnimationPlayer
#
#var cur_chart: SongChart
#
## Note format:
##		[[strum_time, [direction, sustain_length]], ...]
#var player_notes = []
#var opponent_notes = []
#var events = []
#
#func _ready():
#	cur_chart = SongChart.new("bopeebo", "-easy")
#
#	for section in cur_chart.sections:
#		for note in section["sectionNotes"]:
#			var strum_time = note[0] / 1000.0
#
#			var direction = int(note[1])
#			if direction > 3:
#				direction -= 4
#
#			var current_list = player_notes if section["mustHitSection"] else opponent_notes
#			var opposing_list = opponent_notes if section["mustHitSection"] else player_notes
#			var note_list: Array = opposing_list if int(note[1]) > 3 else current_list
#
#			var most_recent_note = note_list[note_list.size() - 1] if !note_list.empty() else null
#
#			if most_recent_note != null && most_recent_note[0] == strum_time:
#				note_list[note_list.size() - 1].append([direction, note[2] / 1000.0])
#			else:
#				note_list.append([strum_time, [direction, note[2] / 1000.0]])
#
#	player_notes = sort_notes(player_notes)
#	opponent_notes = sort_notes(opponent_notes)
#
#	# We reverse the note lists so that we can use pop_back and push_back
#	# b/c those functions are more efficient when used on longer arrays (like these charts)
#	player_notes.invert()
#	opponent_notes.invert()
#
#	Conductor.play_song_with_countdown(cur_chart.song, cur_chart.bpm, cur_chart.vocals)
#
#func sort_notes(note_list):
#	var strum_times = []
#
#	for note_group in note_list:
#		strum_times.append(note_group[0])
#
#	strum_times.sort()
#
#	var new_note_list = []
#	var note_list_dup = note_list.duplicate(true)
#
#	while !note_list_dup.empty():
#		var idx = 0
#
#		while strum_times[0] != note_list_dup[idx][0]:
#			idx += 1
#
#		new_note_list.append(note_list_dup[idx])
#
#		strum_times.remove(0)
#		note_list_dup.remove(idx)
#
#	return new_note_list
#
## Most of this assumes that the songs have a constant BPM, which will probably
## not be true for much longer, so...
## TODO: god damnit
#
## TODO: Plane programming
#
#func _process(delta):
#	player_step_zone.left_just_pressed = Input.is_action_just_pressed("ui_left")
#	player_step_zone.down_just_pressed = Input.is_action_just_pressed("ui_down")
#	player_step_zone.up_just_pressed = Input.is_action_just_pressed("ui_up")
#	player_step_zone.right_just_pressed = Input.is_action_just_pressed("ui_right")
#
#	player_step_zone.left_continued_press = Input.is_action_pressed("ui_left")
#	player_step_zone.down_continued_press = Input.is_action_pressed("ui_down")
#	player_step_zone.up_continued_press = Input.is_action_pressed("ui_up")
#	player_step_zone.right_continued_press = Input.is_action_pressed("ui_right")
#
#	note_process(player_step_zone)
#	note_process(opponent_step_zone)
#
#func note_process(step_zone):
#	var note_list = player_notes if step_zone == player_step_zone else opponent_notes
#
#	if note_list.empty():
#		return
#
#	var last_idx = note_list.size() - 1
#	var cur_note_group = note_list[last_idx]
#	var strum_time = cur_note_group[0]
#
#	if Conductor.song_position >= strum_time - Settings.SCROLL_TIME / Conductor.scroll_speed:
#		for i in range(1, cur_note_group.size()):
#			# The loop starts at 1 since the list of notes comes after the strum time
#			var cur_note = cur_note_group[i]
#
#			var direction = cur_note[0]
#			var sustain_length = cur_note[1]
#
#			var must_press = true if step_zone == player_step_zone else false
#
#			var spawned_note = step_zone.spawn_note(direction,
#													note_mats[direction].inner, note_mats[direction].outer, note_mats[direction].color,
#													strum_time, must_press, sustain_length)
#
#			if step_zone == player_step_zone:
#				spawned_note.connect("good_hit", self, "on_note_good_hit")
##				spawned_note.connect("miss", self, "on_note_miss")
#
#				if "sustain_length" in spawned_note:
#					spawned_note.connect("sustain_part_hit", self, "on_sustain_part_hit")
##					spawned_note.connect("sustain_part_miss", self, "on_sustain_part_miss")
#			else:
##				spawned_note.connect("opponent_hit", self, "change_opponent_anim")
#				spawned_note.connect("opponent_hit", self, "on_opponent_hit")
#
#		note_list.pop_back()
#
## TODO: optimize below, make sure confirm anim for opponent lasts for sustain length
#
#func on_note_good_hit(dir, note_diff):
#	match dir:
#		Conductor.Directions.LEFT:
#			player_left_zone_anim.stop()
#			player_left_zone_anim.play("Confirm")
#
#		Conductor.Directions.DOWN:
#			player_down_zone_anim.stop()
#			player_down_zone_anim.play("Confirm")
#
#		Conductor.Directions.UP:
#			player_up_zone_anim.stop()
#			player_up_zone_anim.play("Confirm")
#
#		Conductor.Directions.RIGHT:
#			player_right_zone_anim.stop()
#			player_right_zone_anim.play("Confirm")
#
#func on_sustain_part_hit(dir, delta):
#	match dir:
#		Conductor.Directions.LEFT:
#			player_left_zone_anim.stop()
#			player_left_zone_anim.play("Confirm")
#
#		Conductor.Directions.DOWN:
#			player_down_zone_anim.stop()
#			player_down_zone_anim.play("Confirm")
#
#		Conductor.Directions.UP:
#			player_up_zone_anim.stop()
#			player_up_zone_anim.play("Confirm")
#
#		Conductor.Directions.RIGHT:
#			player_right_zone_anim.stop()
#			player_right_zone_anim.play("Confirm")
#
#func on_opponent_hit(dir, sustain):
#	match dir:
#		Conductor.Directions.LEFT:
#			opponent_left_zone_anim.stop()
#			opponent_left_zone_anim.play("Confirm")
#
#		Conductor.Directions.DOWN:
#			opponent_down_zone_anim.stop()
#			opponent_down_zone_anim.play("Confirm")
#
#		Conductor.Directions.UP:
#			opponent_up_zone_anim.stop()
#			opponent_up_zone_anim.play("Confirm")
#
#		Conductor.Directions.RIGHT:
#			opponent_right_zone_anim.stop()
#			opponent_right_zone_anim.play("Confirm")
