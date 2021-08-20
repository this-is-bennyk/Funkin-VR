extends Note

var HALF_NOTE_DEPTH = 0.0425

signal sustain_part_hit(dir, delta)
signal sustain_part_miss(delta)

#### Sustained Note Data #####################

var sustain_length = 0 # TODO: CONVERT FROM MSECS TO SECONDS DON'T FORGET!!!!!!!!!!!!
var initial_note_pass = false

#### Sustained Note Graphics #################

onready var sustain_part = $Sustain_Part
onready var opp_sustain_part = $Opp_Sustain_Part

var segments = []
var original_line_length = 0

# TODO: Fix sustaining part

func _ready():
	# Since Note's _ready is called first, most of the things for Sustained_Note are already set up
	
	match direction:
		Directions.LEFT:
			sustain_part.rotation.z = PI / 2
		Directions.DOWN:
			sustain_part.rotation.z = PI
		Directions.RIGHT:
			sustain_part.rotation.z = -PI / 2
	
#	original_line_length = sustain_length * (SCROLL_DISTANCE * Conductor.scroll_speed) / (SCROLL_TIME / Conductor.scroll_speed)
	original_line_length = sustain_length * SCROLL_DISTANCE / SCROLL_TIME * pow(Conductor.scroll_speed, 2)
	
	if must_press:
		sustain_part.get_node("Sustain_Model/Middle/Mesh").material_override.albedo_color = bright_color
		sustain_part.get_node("Sustain_Model/Outer/Mesh").material_override.albedo_color = outer_material.albedo_color
		
		sustain_part.scale.z = original_line_length + HALF_NOTE_DEPTH
		sustain_part.translation.z = -(original_line_length + HALF_NOTE_DEPTH)
		
		opp_sustain_part.queue_free()
		$Opp_Sustain_Endcap.queue_free()
	else:
		opp_sustain_part.get_node("Middle").material_override.albedo_color = bright_color
		opp_sustain_part.get_node("Outer").material_override.albedo_color = outer_material.albedo_color
		
		opp_sustain_part.scale.y = original_line_length
		opp_sustain_part.translation.y = -original_line_length
		
		sustain_part.queue_free()
		opp_sustain_part.show()
		$Opp_Sustain_Endcap.show()

# Processing a sustained note is different from processing a regular one,
# so we gotta duplicate most of the code

# The sustained part of a note isn't counted in the combo,
# but does give you a small boost / drop in health for hitting it.

# You also don't get a penalty for holding down the corresponding control
# after the note, sustained or not, has passed. Only when you release and
# re-press on an empty space do you get penalized.

func start_moving():
	if must_press:
		tween.interpolate_property(self, "translation:z", SCROLL_DISTANCE * Conductor.scroll_speed, \
														  -original_line_length, \
														  SCROLL_TIME / Conductor.scroll_speed + sustain_length)
	else:
		tween.interpolate_property(self, "translation:y", -SCROLL_DISTANCE * Conductor.scroll_speed, \
														  original_line_length, \
														  SCROLL_TIME / Conductor.scroll_speed + sustain_length)
	tween.start()
	
	moving = true

func on_process(delta):
	.on_process(delta)
	sustain_process()

func player_process(delta):
	# Check to see if we can hit the note / we missed it
	
	if Conductor.song_position > strum_time - Conductor.SAFE_ZONE * 1.5 && !ready_to_hit:
		emit_signal("ready_to_hit", direction, sustain_length)
		ready_to_hit = true
	
	if Conductor.song_position > strum_time - Conductor.SAFE_ZONE * 0.5 && \
	   Conductor.song_position < strum_time + sustain_length + Conductor.SAFE_ZONE:
		can_hit = true

	elif Conductor.song_position > strum_time + sustain_length + Conductor.SAFE_ZONE:
		can_hit = false
		emit_signal("sustain_part_miss", delta)
		set_process(false)
		
		yield(get_tree().create_timer(Conductor.get_seconds_per_beat() / 0.5), "timeout")
		queue_free()

	else:
		can_hit = false
	
	# Check to see if we hit the note when we're supposed to
	
	if can_hit:
		var hit_condition = step_zone.lanes[direction].just_pressed if within_safe_zone() && !initial_note_pass else step_zone.lanes[direction].continued_press
		
		if hit_condition:
			if within_safe_zone() && !initial_note_pass:
				emit_signal("good_hit", direction, abs(strum_time - Conductor.song_position), global_transform.origin)
				initial_note_pass = true
				note_model.hide()
			
			else:
				emit_signal("sustain_part_hit", direction, delta)
				
				# Assumption: we are below z = 0 at this point
				if segments.empty() || !segments[segments.size() - 1][1]:
					segments.append([0, true])
				
				if Conductor.song_position > strum_time + sustain_length:
					set_process(false)
					queue_free()
		else:
			if !within_safe_zone():
				if !initial_note_pass:
					emit_signal("miss")
					initial_note_pass = true
				
				else:
					emit_signal("sustain_part_miss", delta)
					
					if segments.empty() || segments[segments.size() - 1][1]:
						segments.append([0, false])

func opponent_process(delta):
	if (must_press && translation.z <= 0) || (!must_press && translation.y >= 0):
		if segments.empty() || !segments[segments.size() - 1][1]:
			segments.append([0, true])
	
	if note_model.visible && Conductor.song_position >= strum_time:
		emit_signal("opponent_hit", direction, sustain_length)
		note_model.hide()
	
	if Conductor.song_position >= strum_time + sustain_length:
		set_process(false)
		queue_free()

func sustain_process():
	if ((must_press && translation.z > 0) || (!must_press && translation.y < 0)) || segments.empty():
		return
	
	if (must_press && translation.z >= -original_line_length) || (!must_press && translation.y <= original_line_length):
		segments[segments.size() - 1][0] = get_remaining_past_sustain_length()
	
	var last_segment = segments[segments.size() - 1]
	var second_to_last_segment = segments[segments.size() - 2]
	
	if last_segment[1]:
		if must_press:
			sustain_part.scale.z = (original_line_length + HALF_NOTE_DEPTH) - get_total_segments_length()
		else:
			opp_sustain_part.scale.y = original_line_length - get_total_segments_length()

func get_total_segments_length():
	if segments.size() == 0:
		return 0
	
	var length = 0
	
	for segment in segments:
		length += segment[0]
	
	return length

# Get the remainder of the sustain length that has already passed the hit zone
# that hasn't been accounted for yet
func get_remaining_past_sustain_length():
	if must_press:
		return abs(translation.z + (get_total_segments_length() - segments[segments.size() - 1][0]))
	else:
		return translation.y - (get_total_segments_length() - segments[segments.size() - 1][0])
