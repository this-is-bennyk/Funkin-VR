extends Spatial

signal ready_to_hit(dir, sustain_length)
signal good_hit(dir, note_diff, global_origin)
signal miss
signal sustain_part_hit(dir, delta)
signal sustain_part_miss(delta)
signal overtap

const JUST_PRESSED_TIME = 1 / 60.0

const MAX_DIST_FROM_ZONE_CENTER = 0.15
#const HITBOX_LOCAL_BOTTOM_RIGHT = Vector3(-0.155, -0.075, -0.2)
const HITBOX_LOCAL_BOTTOM_RIGHT = Vector3(-0.135, -0.041, -0.136)
const POS_ADJUSTMENT = Vector3(0, -0.2, 0)
const SIZE_ADJUSTMENT = Vector3(0, 0.2, 0)
var HALF_NOTE_DEPTH = 0.0425

# ---------- Level Function References ----------

var note_good_hit_callback: FuncRef
var note_miss_callback: FuncRef
var sustain_hit_callback: FuncRef
var sustain_miss_callback: FuncRef
var opponent_hit_callback: FuncRef

# ---------- Level-Specific Variables ----------

export(bool) var must_press = false
export(bool) var step_zone_moves = false
export(bool) var test_step_zone = false

onready var note_models = [
	$Left_Lane/Note_Model,
	$Down_Lane/Note_Model,
	$Up_Lane/Note_Model,
	$Right_Lane/Note_Model
]
onready var sustain_parts = [
	$Left_Lane/Sustain_Part,
	$Down_Lane/Sustain_Part,
	$Up_Lane/Sustain_Part,
	$Right_Lane/Sustain_Part
]
onready var physical_note_list = $Note_List
onready var miss_sound_player = get_node_or_null("Miss_Sound_Player")

var particles = []

# Format in non-inverted order: PRA(strum_time, num_of_notes, dir, sustain_length, (dir, sustain_length, ...), ...)
var notes: Array = []
var notes_in_play = []

# Only needed for player
var lanes
onready var lane_tween = get_node_or_null("Lane_Tween")

# Max of two zones
var zones_left_hand_in: Array = [-1, -1]
var zones_right_hand_in: Array = [-1, -1]

# ---------- Game Processing ----------

func _ready():
	on_ready()

func on_ready():
	adapt_to_video_driver()
	
	if must_press:
		player_setup()
	else:
		opponent_setup()

func player_setup():
	if !test_step_zone:
		note_good_hit_callback = funcref(get_parent(), "on_note_good_hit")
		note_miss_callback = funcref(get_parent(), "on_note_miss")
		sustain_hit_callback = funcref(get_parent(), "on_sustain_part_hit")
		sustain_miss_callback = funcref(get_parent(), "on_sustain_part_miss")
	
	translation = Settings.get_setting("step_zone", "location")
	rotation_degrees.x = Settings.get_setting("step_zone", "angle")
	
	var new_scale = Settings.get_setting("step_zone", "scale")
	scale = Vector3(new_scale, new_scale, new_scale)
	
	lanes = []
	
	for judgement_note in [$Left, $Down, $Up, $Right]:
		var hitbox_pos = judgement_note.global_transform.origin + (HITBOX_LOCAL_BOTTOM_RIGHT * scale.x) + (POS_ADJUSTMENT * scale.x)
		var hitbox_size = (HITBOX_LOCAL_BOTTOM_RIGHT.abs() * scale.x * 2) + (SIZE_ADJUSTMENT.abs() * scale.x)
#			hitbox_size += Vector3(0, 0, EXTRA_DEPTH * scale.x) if !(judgement_note == $Left || judgement_note == $Right) else Vector3(0, 0, (0.1 + EXTRA_DEPTH) * scale.x)
		
		if get_node_or_null("../" + judgement_note.name + "_Box"):
			var visual_box: Spatial = get_node("../" + judgement_note.name + "_Box")
			visual_box.global_transform.origin = hitbox_pos
			visual_box.scale = hitbox_size
		
		var lane_plane
		var lane_corner
		var lane_color: Color
		match judgement_note.name:
			"Left":
				lane_plane = $Left_Lane/Left_Plane
				lane_corner = $Left_Lane/Corner
				lane_color = $Left_Lane/Left_Plane.material_override.get_shader_param("color")
				
			"Down":
				lane_plane = $Down_Lane/Down_Plane
				lane_corner = $Down_Lane/Corner
				lane_color = $Down_Lane/Down_Plane.material_override.get_shader_param("color")
				
			"Up":
				lane_plane = $Up_Lane/Up_Plane
				lane_corner = $Up_Lane/Corner
				lane_color = $Up_Lane/Up_Plane.material_override.get_shader_param("color")
			
			"Right":
				lane_plane = $Right_Lane/Right_Plane
				lane_corner = $Right_Lane/Corner
				lane_color = $Right_Lane/Right_Plane.material_override.get_shader_param("color")
		
		lanes.append({
			judgement_origin = judgement_note.global_transform.origin,
			plane = lane_plane,
			corner = lane_corner,
			color = lane_color,
			
			just_pressed = false,
			# TODO: remove this shit
			just_pressed_time = 0, # The amount of time the game registers a just-press
			just_pressed_buffer = 0, # The amount of time in which you're allowed to do a just-press. 0 = not allowed to just-press
			continued_press = false,
			
			hitbox = AABB(hitbox_pos, hitbox_size)
		})

func opponent_setup():
	opponent_hit_callback = funcref(get_parent(), "on_opponent_hit")

func update(delta):
	if !notes.empty():
		note_spawn_process()
	
	if !notes_in_play.empty():
		note_movement_process(delta)
		
	if must_press:
		player_process(delta)
	else:
		opponent_process()

func note_spawn_process():
	if Conductor.song_position >= notes[len(notes) - 1] - Settings.SCROLL_TIME / Conductor.scroll_speed:
		var strum_time = notes[len(notes) - 1]
		notes.remove(len(notes) - 1)
		
		var num_of_notes = int(notes[len(notes) - 1])
		notes.remove(len(notes) - 1)
		
		for i in range(num_of_notes):
			var direction = int(notes[len(notes) - 1])
			notes.remove(len(notes) - 1)
			
			var sustain_length = notes[len(notes) - 1]
			notes.remove(len(notes) - 1)
			
			spawn_note(direction, strum_time, sustain_length)

func note_movement_process(delta):
	var idxs_to_delete = PoolIntArray()
	
	for idx in len(notes_in_play):
		var note = notes_in_play[idx]
#		var scroll_delta = Settings.SCROLL_DISTANCE / Settings.SCROLL_TIME * Conductor.scroll_speed * delta
		
		var scroll_dist = Settings.SCROLL_DISTANCE * Conductor.scroll_speed
		var scroll_dir = 1 if must_press else -1
		var relative_song_pos = inverse_lerp(note.strum_time - Settings.SCROLL_TIME * Conductor.scroll_speed, note.strum_time, Conductor.song_position)
		var final_location = lerp(scroll_dist * scroll_dir, 0, relative_song_pos)
		
		# Make the note move
		if "note_model" in note:
			if must_press:
				note.note_model.translation.z = final_location
			else:
				note.note_model.translation.y = final_location
		
		if "sustain_part" in note:
			if must_press:
				note.sustain_part.translation.z = final_location + note.original_sustain_part_length
			else:
				note.sustain_part.translation.y = final_location - note.original_sustain_part_length
		
#		if must_press:
#			if "note_model" in note:
#				note.note_model.translation.z -= scroll_delta
#
#			if "sustain_part" in note:
#				note.sustain_part.translation.z -= scroll_delta
#		else:
#			if "note_model" in note:
#				note.note_model.translation.y += scroll_delta
#
#			if "sustain_part" in note:
#				note.sustain_part.translation.y += scroll_delta
		
		# Check if it needs to be shown
		if "note_model" in note && !note.note_model.visible:
			var visible_check = note.note_model.translation.z <= Settings.SCROLL_DISTANCE if must_press else note.note_model.translation.y >= -Settings.SCROLL_DISTANCE
			
			if visible_check:
				note.note_model.visible = true
				
				if "sustain_part" in note:
					note.sustain_part.visible = true
				
				particles[note.direction].restart()
		
		# Check if we need to delete it
		if note.deletion_timer is float:
			if note.deletion_timer <= 0:
				if "note_model" in note:
					note.note_model.queue_free()
				if "sustain_part" in note:
					note.sustain_part.queue_free()
				
				idxs_to_delete.append(idx)
			else:
				note.deletion_timer -= delta
	
	# We invert idxs_to_delete bc if we start deleting from the start of the list, the order will be messed up
	# and delete the wrong notes
	idxs_to_delete.invert()
	
	for idx in idxs_to_delete:
		notes_in_play.remove(idx)

func player_process(delta):
	player_zone_process(delta)
	if !test_step_zone:
		player_note_process(delta)

func player_zone_process(delta):
	for dir in Conductor.Directions.size():
		if lanes[dir].just_pressed_time > 0:
			lanes[dir].just_pressed_time -= delta
			
			# TODO: Replace these with tween flashes
			lanes[dir].plane.material_override.set_shader_param("color",
													 Color.white.linear_interpolate(lanes[dir].color, lanes[dir].just_pressed_time / JUST_PRESSED_TIME))
			lanes[dir].corner.material_override.albedo_color = lanes[dir].plane.material_override.get_shader_param("color")
		else:
			lanes[dir].just_pressed_time = 0
			lanes[dir].just_pressed = false
			
			# TODO: Replace these with tween flashes
			lanes[dir].plane.material_override.set_shader_param("color", lanes[dir].color)
			lanes[dir].corner.material_override.albedo_color = lanes[dir].color
		
		if lanes[dir].just_pressed_buffer > 0:
			lanes[dir].just_pressed_buffer -= delta
		else:
			lanes[dir].just_pressed_buffer = 0
	
	zones_left_hand_in = []
	zones_right_hand_in = []
	
	for child in get_children():
		var dir
		
		match child.name:
			"Left_Lane":
				dir = Conductor.Directions.LEFT
			"Down_Lane":
				dir = Conductor.Directions.DOWN
			"Up_Lane":
				dir = Conductor.Directions.UP
			"Right_Lane":
				dir = Conductor.Directions.RIGHT
			_:
				continue
		
		if dir == null:
			continue
		
		# okay so i added really stupid keyboard support because
		# i kinda wanted to play the charts while testing
		# feel free to remove this lmao - codist
#		var keyboardButton = ""
#		if (Player.DEBUG):
#			match (dir):
#				Conductor.Directions.LEFT:
#					keyboardButton = "ui_left"
#				Conductor.Directions.DOWN:
#					keyboardButton = "ui_down"
#				Conductor.Directions.UP:
#					keyboardButton = "ui_up"
#				Conductor.Directions.RIGHT:
#					keyboardButton = "ui_right"

		var left_hand_within_zone = lanes[dir].hitbox.has_point(Player.left_hand.global_transform.origin)
		var right_hand_within_zone = lanes[dir].hitbox.has_point(Player.right_hand.global_transform.origin)
		
#		if GDScriptX.xor(left_hand_within_zone, right_hand_within_zone) || Input.is_action_just_pressed(keyboardButton):
		if GDScriptX.xor(left_hand_within_zone, right_hand_within_zone):
			if left_hand_within_zone:
				zones_left_hand_in.append(dir)
			else:
				zones_right_hand_in.append(dir)
			
			if !lanes[dir].continued_press:
#				if lanes[dir].just_pressed_buffer == 0:
#					emit_signal("overtap")
#				el
				if lanes[dir].just_pressed_time == 0:
					lanes[dir].just_pressed = true
					lanes[dir].just_pressed_time = JUST_PRESSED_TIME
			
			lanes[dir].continued_press = true
			
			var zone_anim_player: AnimationPlayer
			match dir:
				Conductor.Directions.LEFT:  zone_anim_player = $Left/AnimationPlayer
				Conductor.Directions.DOWN:  zone_anim_player = $Down/AnimationPlayer
				Conductor.Directions.UP:    zone_anim_player = $Up/AnimationPlayer
				Conductor.Directions.RIGHT: zone_anim_player = $Right/AnimationPlayer
			
			if !zone_anim_player.current_animation == "Confirm":
				zone_anim_player.stop()
				zone_anim_player.play("Press")
			
		else:
			lanes[dir].continued_press = false
	
	# ASSUMPTION: zones_left_hand_in and zones_right_hand_in both have a length that is 2 or less
	
	if len(zones_left_hand_in) == 0:
		zones_left_hand_in = [-1, -1]
	elif len(zones_left_hand_in) == 1:
		zones_left_hand_in.append(-1)
	elif len(zones_left_hand_in) > 2:
		assert(false)
	
	if len(zones_right_hand_in) == 0:
		zones_right_hand_in = [-1, -1]
	elif len(zones_right_hand_in) == 1:
		zones_right_hand_in.append(-1)
	elif len(zones_right_hand_in) > 2:
		assert(false)

func player_note_process(delta):
#	var valid_lane_press = [false, false, false, false]
	
	for note in notes_in_play:
#		var dir = note.direction
#
#		if dir in zones_left_hand_in || dir in zones_right_hand_in:
		if "sustain_part" in note:
			player_sustained_note_check(note, delta)
		else:
			player_regular_note_check(note)

# Player Process Helper Functions

func within_safe_zone(strum_time, sustain_length = 0):
	return Conductor.song_position >= strum_time - Conductor.SAFE_ZONE * 0.5 && \
		   Conductor.song_position <= strum_time + sustain_length + Conductor.SAFE_ZONE

func player_regular_note_check(note):
	if note.deletion_timer == null:
		if within_safe_zone(note.strum_time) && lanes[note.direction].just_pressed:
			note_good_hit_callback.call_func(note.direction, abs(note.strum_time - Conductor.song_position), lanes[note.direction].judgement_origin)
	#		emit_signal("good_hit", note.direction, abs(note.strum_time - Conductor.song_position), lanes[note.direction].judgement_origin)
			note.deletion_timer = 0.0
		
	#	elif !within_safe_zone(note.strum_time) && Conductor.song_position >= note.strum_time + Conductor.SAFE_ZONE:
		elif Conductor.song_position >= note.strum_time + Conductor.SAFE_ZONE:
			note_miss_callback.call_func()
	#		emit_signal("miss")
			note.deletion_timer = float(Settings.SCROLL_TIME / Conductor.scroll_speed) # These should always be floats but it can't hurt to be sure

func player_sustained_note_check(note, delta):
	if note.deletion_timer == null:
		# First, we check whether or not we hit the note part of the sustained note...
		if "note_model" in note:
			if within_safe_zone(note.strum_time) && lanes[note.direction].just_pressed:
				note_good_hit_callback.call_func(note.direction, abs(note.strum_time - Conductor.song_position), lanes[note.direction].judgement_origin)
	#			emit_signal("good_hit", note.direction, abs(note.strum_time - Conductor.song_position), lanes[note.direction].judgement_origin)
				
				note.note_model.queue_free()
				note.erase("note_model")
			
	#		elif !within_safe_zone(note.strum_time) && Conductor.song_position >= note.strum_time + Conductor.SAFE_ZONE:
			elif Conductor.song_position >= note.strum_time + Conductor.SAFE_ZONE:
				note_miss_callback.call_func()
	#			emit_signal("miss")
				
				note.note_model.queue_free()
				note.erase("note_model")
		
		# ...then we check to see if we hit the sustain part of the sustained note
		else:
			if within_safe_zone(note.strum_time, note.sustain_length):
				if lanes[note.direction].continued_press:
					sustain_hit_callback.call_func(note.direction, delta)
	#				emit_signal("sustain_part_hit", note.direction, delta)
					
					if Conductor.song_position >= note.strum_time + note.sustain_length:
						note.deletion_timer = 0.0
					elif note.sustain_part.translation.z >= 0:
#						note.sustain_part.scale.z = (note.original_sustain_part_length + HALF_NOTE_DEPTH) - (note.original_sustain_part_length - note.sustain_part.translation.z)
						note.sustain_part.get_node("Sustain_Length").scale.y = note.sustain_part.translation.z
				else:
					sustain_miss_callback.call_func(delta)
	#				emit_signal("sustain_part_miss", delta)
			
	#		elif !within_safe_zone(note.strum_time, note.sustain_length) && Conductor.song_position >= note.strum_time + note.sustain_length + Conductor.SAFE_ZONE:
			elif Conductor.song_position >= note.strum_time + note.sustain_length + Conductor.SAFE_ZONE:
				sustain_miss_callback.call_func(delta)
	#			emit_signal("sustain_part_miss", delta)
				note.deletion_timer = float(Settings.SCROLL_TIME / Conductor.scroll_speed)

func opponent_process():
	for note in notes_in_play:
		if "sustain_part" in note:
			if note.sustain_part.translation.y >= -note.original_sustain_part_length:
				note.sustain_part.get_node("Sustain_Length").scale.y = abs(note.sustain_part.translation.y)
			
			if Conductor.song_position >= note.strum_time && "note_model" in note:
				opponent_hit_callback.call_func(note.direction, note.sustain_length)
#				emit_signal("opponent_hit", note.direction, note.sustain_length)
				
				note.note_model.queue_free()
				note.erase("note_model")
		
		if Conductor.song_position >= note.strum_time + note.sustain_length:
			if !"sustain_part" in note:
				opponent_hit_callback.call_func(note.direction, 0)
#				emit_signal("opponent_hit", note.direction, 0)
			
			note.deletion_timer = 0.0

# ---------- Note Creation ----------

# ASSUMPTION: variable notes is empty
func generate_notes(chart):
	# First, we generate notes into a temp list
	var tmp_note_list = []
	var most_recent_note = []
	
	for section in chart.sections:
		for note in section["sectionNotes"]:
			var strum_time = note[0] / 1000.0
			var sustain_length = note[2] / 1000.0
			
			var direction = int(note[1])
			if direction > 3:
				direction -= 4
			
			var should_add_to_list
			
			if must_press:
				should_add_to_list = (section["mustHitSection"] && int(note[1]) <= 3) || (!section["mustHitSection"] && int(note[1]) > 3)
			else:
				should_add_to_list = (!section["mustHitSection"] && int(note[1]) <= 3) || (section["mustHitSection"] && int(note[1]) > 3)
			
			if should_add_to_list:
				if !most_recent_note.empty():
					if most_recent_note[0] == strum_time:
						most_recent_note[1] += 1.0
						most_recent_note.append_array([float(direction), sustain_length])
					else:
						tmp_note_list.append(most_recent_note)
						most_recent_note = [strum_time, 1.0, float(direction), sustain_length]
				else:
					most_recent_note = [strum_time, 1.0, float(direction), sustain_length]
	# Have to manually add the last note
	tmp_note_list.append(most_recent_note)
	
	# Then we sort the temp list and add its values into the actual list
	var strum_times = []
	
	for tmp_note in tmp_note_list:
		strum_times.append(tmp_note[0])
	
	strum_times.sort()
	
	while !tmp_note_list.empty():
		var idx = 0
		
		while strum_times[0] != tmp_note_list[idx][0]:
			idx += 1
		
		notes.append_array(tmp_note_list[idx])
		
		strum_times.remove(0)
		tmp_note_list.remove(idx)
	
	notes.invert()
	set_process(true)

func spawn_note(dir, strum_time_, sustain_length_ = 0):
	# Duplicate the note model templates and calculate the sustain part's length if needed
	var new_note_model = note_models[dir].duplicate()
	var new_sustain_part = sustain_parts[dir].duplicate() if sustain_length_ > 0 else null
#	var original_sustain_part_length = sustain_length_ * Settings.SCROLL_DISTANCE / Settings.SCROLL_TIME * pow(Conductor.scroll_speed, 2) if sustain_length_ > 0 else 0
	var original_sustain_part_length = sustain_length_ * (Settings.SCROLL_DISTANCE * Conductor.scroll_speed) / (Settings.SCROLL_TIME / Conductor.scroll_speed) if sustain_length_ > 0 else 0
	
	# Find the lane it's supposed to be in
	var spawn_lane
	match dir:
		Conductor.Directions.LEFT:
			spawn_lane = $Left_Lane
		Conductor.Directions.DOWN:
			spawn_lane = $Down_Lane
		Conductor.Directions.UP:
			spawn_lane = $Up_Lane
		Conductor.Directions.RIGHT:
			spawn_lane = $Right_Lane
	
	# Add the note model and move it to its starting position
	physical_note_list.add_child(new_note_model)
	new_note_model.global_transform.origin = spawn_lane.global_transform.origin
	
	if must_press:
		new_note_model.translation.z = Settings.SCROLL_DISTANCE * Conductor.scroll_speed
	else:
		new_note_model.translation.y = -Settings.SCROLL_DISTANCE * Conductor.scroll_speed
	
	if sustain_length_ > 0:
		physical_note_list.add_child(new_sustain_part)
		new_sustain_part.global_transform.origin = new_note_model.global_transform.origin
		
		if must_press:
			new_sustain_part.translation.z += original_sustain_part_length
		else:
			new_sustain_part.translation.y -= original_sustain_part_length
		new_sustain_part.get_node("Sustain_Length").scale.y = original_sustain_part_length
	
	var note_data = {
		direction = dir,
		strum_time = strum_time_,
		sustain_length = sustain_length_,
		note_model = new_note_model,
		deletion_timer = null
	}
	if sustain_length_ > 0:
		note_data.sustain_part = new_sustain_part
		note_data.original_sustain_part_length = original_sustain_part_length
	
	notes_in_play.append(note_data)

func clear_notes():
	for obj in physical_note_list.get_children():
		obj.queue_free()
	
	notes = []
	notes_in_play = []

# ---------- Video Driver Functions ----------

func adapt_to_video_driver():
	var is_gles2 = OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES2
	
	_adapt_particles_to_vid_driver(is_gles2)
#	_adapt_notes_to_vid_driver(is_gles2)

func _adapt_particles_to_vid_driver(is_gles2):
	if is_gles2:
		particles = [
			$Left_Lane/Particles_GLES2,
			$Down_Lane/Particles_GLES2,
			$Up_Lane/Particles_GLES2,
			$Right_Lane/Particles_GLES2
		]
		$Left_Lane/Particles.queue_free()
		$Down_Lane/Particles.queue_free()
		$Up_Lane/Particles.queue_free()
		$Right_Lane/Particles.queue_free()
		
	else:
		particles = [
			$Left_Lane/Particles,
			$Down_Lane/Particles,
			$Up_Lane/Particles,
			$Right_Lane/Particles
		]
		$Left_Lane/Particles_GLES2.queue_free()
		$Down_Lane/Particles_GLES2.queue_free()
		$Up_Lane/Particles_GLES2.queue_free()
		$Right_Lane/Particles_GLES2.queue_free()

#func _adapt_notes_to_vid_driver(is_gles2):
#	# TMPFIX: GLES2 inner note materials
#	# TODO: Figure out what the actual fuck is wrong with the original down note in GLES2
#	if is_gles2:
#		$Left_Lane/Note_Model/Inner/Mesh.material_override = preload("res://assets/models/note/materials/Left_Note_Inner_GLES2.tres")
#		$Down_Lane/Note_Model/Inner/Mesh.material_override = preload("res://assets/models/note/materials/Down_Note_Inner_GLES2.tres")
#		$Up_Lane/Note_Model/Inner/Mesh.material_override = preload("res://assets/models/note/materials/Up_Note_Inner_GLES2.tres")
#		$Right_Lane/Note_Model/Inner/Mesh.material_override = preload("res://assets/models/note/materials/Right_Note_Inner_GLES2.tres")
