extends "res://packages/fnfvr/resources/scripts/game/levels/LevelVR.gd"

const CAR_PASS_NOISES = [
	preload("res://packages/fnf/resources/sounds/carPass0.ogg"),
	preload("res://packages/fnf/resources/sounds/carPass1.ogg")
]

const CAR_CHANCE = 0.1

onready var car_anim = $Car/AnimationPlayer
onready var car_pass_sound = $Car_Pass_Sound

func do_level_specific_prep():
	# TODO: Figure out EXTREMELY weird issue where's GF's face
	# doesn't get uncrumpled on GLES3 even tho I set it up
	# exactly the same way as the other anims?????????
	get_performer("metronome").play_anim("Dance_Left")

func send_fast_car():
	if randf() <= CAR_CHANCE && !(car_anim.is_playing() || car_pass_sound.playing):
		var sound_choice = randi() % len(CAR_PASS_NOISES)
		var anim_delay = 0.3 if sound_choice == 0 else 0.6
		
		car_pass_sound.stop()
		car_pass_sound.stream = CAR_PASS_NOISES[randi() % len(CAR_PASS_NOISES)]
		car_pass_sound.play()
		
		get_tree().create_timer(anim_delay / Conductor.pitch_scale, false).connect("timeout", car_anim, "play", ["Zoom"], CONNECT_ONESHOT)
