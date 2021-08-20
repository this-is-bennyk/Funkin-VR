extends Skeleton

# Based on Gonkee's audio visualiser for Godot 3.2 - full tutorial https://youtu.be/AwgSICbGxJM
# If you use this, I would prefer if you gave credit to me and my channel

onready var spectrum = AudioServer.get_bus_effect_instance(1, 0)

var min_freq = 5000
var max_freq = 10000

var max_db = 0
var min_db = -40

var accel = 20
# Histogram with a definition of one
var bar = 0

func _ready():
	max_db += Conductor.volume_db
	min_db += Conductor.volume_db

func _process(delta):
	var freq = min_freq
	var interval = max_freq - min_freq
	
	var freqrange_low = float(freq - min_freq) / float(max_freq - min_freq)
	freqrange_low = freqrange_low * freqrange_low * freqrange_low * freqrange_low
	freqrange_low = lerp(min_freq, max_freq, freqrange_low)
	
	freq += interval
	
	var freqrange_high = float(freq - min_freq) / float(max_freq - min_freq)
	freqrange_high = freqrange_high * freqrange_high * freqrange_high * freqrange_high
	freqrange_high = lerp(min_freq, max_freq, freqrange_high)
	
	var mag = spectrum.get_magnitude_for_frequency_range(freqrange_low, freqrange_high)
	mag = linear2db(mag.length())
	mag = (mag - min_db) / (max_db - min_db)
	
	mag += 0.3 * (freq - min_freq) / (max_freq - min_freq)
#	mag = clamp(mag, 0.05, 1)
	mag = clamp(mag, 0, 1)
	
	bar = lerp(bar, mag, accel * delta)
	
	bump_speakers()

func bump_speakers():
	set_bone_pose(find_bone("Speaker1"), Transform().scaled(lerp(Vector3.ONE, Vector3(1.2, 1.2, 1.1), bar)))
	set_bone_pose(find_bone("Speaker2"), Transform().scaled(lerp(Vector3.ONE, Vector3(1.2, 1.2, 1.1), bar)))
	
	set_bone_pose(find_bone("Right Speaker"), Transform().scaled(lerp(Vector3.ONE, Vector3.ONE * 1.2, bar)))
	set_bone_pose(find_bone("Speaker1.R"), Transform().scaled(lerp(Vector3.ONE, Vector3.ONE * 1.1, bar)))
	set_bone_pose(find_bone("Speaker2.R"), Transform().scaled(lerp(Vector3.ONE, Vector3.ONE * 1.1, bar)))
	
	set_bone_pose(find_bone("Left Speaker"), Transform().scaled(lerp(Vector3.ONE, Vector3.ONE * 1.2, bar)))
	set_bone_pose(find_bone("Speaker1.L"), Transform().scaled(lerp(Vector3.ONE, Vector3.ONE * 1.1, bar)))
	set_bone_pose(find_bone("Speaker2.L"), Transform().scaled(lerp(Vector3.ONE, Vector3.ONE * 1.1, bar)))
