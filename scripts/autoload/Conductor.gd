extends AudioStreamPlayer

signal quarter_hit(quarter)
signal eighth_hit(eighth)
signal sixteenth_hit(sixteenth)

enum Notes {QUARTER, EIGHTH, SIXTEENTH}
enum Directions {LEFT, DOWN, UP, RIGHT}

const SAFE_FRAMES = 10
# SAFE_ZONE: the amount of time (in seconds, assuming 60 FPS)
#			 before / after the note to be considered a valid hit.
const SAFE_ZONE = SAFE_FRAMES / 60.0
# COUNTDOWN_CONSTANT: the # of beats before a level song plays
#						(for the 321GO! sequence).
const COUNTDOWN_CONSTANT = -4

onready var vocals = $Vocals
onready var countdown_timer = $Countdown_Timer

var bpm: float = 60
var scroll_speed = 2.0

var song_position: float = 0 # in seconds
# time_begin: the exact timestamp (since engine launch / last pause in microseconds)
#			  that the current song started playing at.
var previous_frame_time: int = 0
var last_reported_playhead_position: float = 0
var counting_down = false

# Assigned -1 to include 1st beat of the song
var last_quarter   = -1
var last_eighth    = -1
var last_sixteenth = -1

# Last time (in seconds) the BPM changed
var last_bpm_change = 0
var last_quarter_before_change   = 0
var last_eighth_before_change    = 0
var last_sixteenth_before_change = 0

#### (Re-)Initialization #####################

var DEBUG = true

func _ready():
	$BPM_Debug.visible = DEBUG
	set_process(false)

func play_song(song, bpm_, vocals_ = null, scroll_speed_ = 1):
	if playing:
		stop_song()
	
	stream = song
	bpm = bpm_
	scroll_speed = scroll_speed_
	
	if vocals:
		vocals.stream = vocals_
	vocals.volume_db = 0
	
	song_position = 0

	last_quarter   = -1
	last_eighth    = -1
	last_sixteenth = -1
	
	last_bpm_change = 0
	last_quarter_before_change   = 0
	last_eighth_before_change    = 0
	last_sixteenth_before_change = 0
	
	previous_frame_time = OS.get_ticks_usec()
	last_reported_playhead_position = 0
	
	play()
	if vocals_:
		vocals.play()
	
	if Player.DEBUG:
		$BPM_Debug/Label.text = str(bpm)
	
	set_process(true)

func play_song_with_countdown(song, bpm_, vocals_ = null, scroll_speed_ = 1):
	if playing:
		stop_song()
	
	bpm = bpm_
	
	last_quarter   = COUNTDOWN_CONSTANT - 1
	last_eighth    = COUNTDOWN_CONSTANT - 1
	last_sixteenth = COUNTDOWN_CONSTANT - 1
	
	countdown_timer.start(-COUNTDOWN_CONSTANT * get_seconds_per_beat())
	counting_down = true
	set_process(true)
	
	# Countdown should be handled by game
	var countdown_co = yield(self, "quarter_hit")
	
	while countdown_co < 0:
		countdown_co = yield(self, "quarter_hit")
	
	counting_down = false
	set_process(false)
	# TODO: fucking scroll speed brokey
#	play_song(song, bpm_, vocals_, scroll_speed_)
	play_song(song, bpm_, vocals_)

func stop_song():
	stop()
	vocals.stop()
	set_process(false)

#### Update Loop #####################

func _process(delta):
	update_time(delta)
	
	for note_name in ["quarter", "eighth", "sixteenth"]:
		var cur_beat = call("get_" + note_name, true)
		var last_beat = get("last_" + note_name)
		
		if cur_beat > last_beat:
			emit_signal(note_name + "_hit", cur_beat)
			set("last_" + note_name, cur_beat)
			
			if note_name == "quarter" && Player.DEBUG:
				print(cur_beat)
				$BPM_Debug/Tween.stop_all()
				$BPM_Debug/Tween.interpolate_property($BPM_Debug/Polygon2D, "scale",
													Vector2(70, 70), Vector2(60, 60), get_seconds_per_beat())
				$BPM_Debug/Tween.start()

# update_time: Gets precise playback position by obtaining the ticks since the engine started,
# compensates for audio latency and previous time when paused, and accounts for if the song hasn't
# started yet.
func update_time(delta):
	if counting_down:
		song_position = -countdown_timer.time_left
	else:
		song_position = max(0, song_position + (OS.get_ticks_usec() - previous_frame_time) / 1000000.0)
#		song_position += previous_frame_time - OS.get_ticks_usec() / 1000000.0
		previous_frame_time = OS.get_ticks_usec()
		
		if get_playback_position() != last_reported_playhead_position:
			song_position = (song_position + get_playback_position()) / 2.0
			last_reported_playhead_position = get_playback_position()
		
#		print("sp: " + str(song_position) + ", ph: " + str(get_playback_position()))
		
#		song_position = max(0, ((OS.get_ticks_usec() - previous_frame_time) / 1000000.0) + song_pos_at_pause - (AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()))

#### Music Functions #################

func get_seconds_per_beat():
	return 60.0 / bpm

func get_beat(note, floored):
	var divisor = 1.0
	var last_beat_name = "quarter"
	
	match note:
		Notes.EIGHTH:
			divisor = 2.0
			last_beat_name = "eighth"
		Notes.SIXTEENTH:
			divisor = 4.0
			last_beat_name = "sixteenth"
	
	# Assumption: There are no BPM changes before the song starts
	# (why would you even do that? that sounds like a dumbass idea)
	if counting_down:
		if floored:
			return int(floor(song_position / (get_seconds_per_beat() / divisor)))
		return song_position / (get_seconds_per_beat() / divisor)
	
	var last_beat_before_change = get("last_" + last_beat_name + "_before_change")
	
	if floored:
		return last_beat_before_change + int(floor((song_position - last_bpm_change) / (get_seconds_per_beat() / divisor)))
	return last_beat_before_change + (song_position - last_bpm_change) / (get_seconds_per_beat() / divisor)

func is_beat(note, desired_beat):
	return get_beat(note, false) >= desired_beat

func get_quarter(floored):   return get_beat(Notes.QUARTER, floored)
func get_eighth(floored):    return get_beat(Notes.EIGHTH, floored)
func get_sixteenth(floored): return get_beat(Notes.SIXTEENTH, floored)

func is_quarter(desired_quarter):     return is_beat(Notes.QUARTER, desired_quarter)
func is_eighth(desired_eighth):       return is_beat(Notes.EIGHTH, desired_eighth)
func is_sixteenth(desired_sixteenth): return is_beat(Notes.SIXTEENTH, desired_sixteenth)

func get_quarter_length():   return get_seconds_per_beat()
func get_eighth_length():    return get_seconds_per_beat() / 2.0
func get_sixteenth_length(): return get_seconds_per_beat() / 4.0

#### Level Functions #################

func get_speed_difference(): return scroll_speed - 1.0
func get_actual_scroll_speed(): return 1.0 + get_speed_difference() / 2.0

# ASSUMPTION: BPM changes happen on quarters
# i don't even wanna think about if it doesn't
func change_bpm(bpm_):
	# The reason we set the last beat changes BEFORE the BPM change is
	# bc if we do it the other way around, the beat calculations get fucky wucky (scientific term)
	# (we'd be calculating the last beats with the current BPM, which is wrong)
	
	last_quarter_before_change = int(round(get_quarter(false)))
	last_eighth_before_change = int(round(get_eighth(false)))
	last_sixteenth_before_change = int(round(get_sixteenth(false)))
	
	last_bpm_change = song_position
	
	bpm = bpm_
	
	if Player.DEBUG:
		$BPM_Debug/Label.text = str(bpm)
