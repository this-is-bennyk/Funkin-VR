extends Level

const THUNDER_SOUNDS = [
	preload("res://assets/sounds/thunder_1.ogg"),
	preload("res://assets/sounds/thunder_2.ogg")
]

onready var thunder = $Thunder
onready var thunder_anim = $Spooky_Environment/AnimationPlayer

func on_ready():
	opponent_icons_idx = 15
	
	opponent = $Spooky_Kids
	metronome = $Girlfriend
	
	.on_ready()

func set_songs():
	if !song_json_names.empty():
		return
	
	song_json_names = ["spookeez", "south", "monster"]
	extensions = ["mp3", "ogg", "ogg"]

func set_video_driver_stuff():
	if OS.get_name() == "Android":
		$Spooky_Environment/OmniLight.hide()
		$Spooky_Environment/SpotLight.hide()
		$Spooky_Environment/GLES2_Light.show()

func do_level_prep():
	if thunder:
		thunder.stop()
	if thunder_anim:
		thunder_anim.stop()
		thunder_anim.seek(thunder_anim.get_animation("Thunder").length, true)
	
	random_events = [
		[
			8,
			[8, 24],
			Conductor.Notes.QUARTER,
			funcref(self, "do_lightning_strike"),
			[]
		]
	]
	
	match songs[0].song_name:
		"South":
			opponent.idle_speed = 165 / 60.0
		"Monster":
			$Spooky_Kids.hide()
			$Monster.show()
			$Monster.get_node("Monster Armature/Skeleton/Monster Christmas Hat").hide()
			
			opponent = $Monster
			opponent_icons_idx = 35
			
			generate_bpm_changes()

func do_lightning_strike():
	thunder.stop()
	thunder.stream = THUNDER_SOUNDS[randi() % 2]
	thunder.play()
	
	thunder_anim.stop()
	var thunder_anim_suffix = "_GLES2" if OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES2 else ""
	thunder_anim.play("Thunder" + thunder_anim_suffix)
	
	metronome.play_anim("Fear")
