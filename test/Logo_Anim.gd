extends Spatial

onready var tween = $Tween

var logo_anim_beats = [
	11,

	12,
	12.25,
	12.5,
	12.75,

	13,
	13.25,
	13.5,
	13.75,

	14,
	14.25,
	14.5,
	14.75,

	15,
	15.25,
	15.5,
	15.75,
	
	16
]

func _ready():
	for child in get_children():
		if child.name == "Logo1":
			child.opacity = 0
		elif "Logo" in child.name:
			child.hide()
	
	Conductor.play_song(load("res://assets/music/freakyMenu.ogg"), 102)
#	Conductor.play_song_with_countdown(load("res://assets/music/freakyMenu.ogg"), 102)

func _process(delta):
	if logo_anim_beats.size() != 0:
		if Conductor.is_quarter(logo_anim_beats[0]):
			match logo_anim_beats[0]:
				11:
					tween.interpolate_property($Logo1, "opacity", 0, 1, Conductor.get_seconds_per_beat(), Tween.TRANS_EXPO, Tween.EASE_OUT)
				16:
					for child in get_children():
						if child.name == "Logo18":
							child.show()
						elif "Logo" in child.name:
							child.hide()
					
					tween.interpolate_property($Camera/ColorRect, "color:a", 1, 0, 4)
				_:
					var frame = get_node("Logo" + str(17 - logo_anim_beats.size() + 2))
					frame.show()
					
					if logo_anim_beats[0] == 15.5:
						tween.interpolate_property(frame, "translation:z", 1.5, 0.002, Conductor.get_seconds_per_beat() / 4.0, Tween.TRANS_BACK, Tween.EASE_OUT)
					elif logo_anim_beats[0] == 15.75:
						tween.interpolate_property(frame, "translation:z", 1.5, 0.001, Conductor.get_seconds_per_beat() / 4.0, Tween.TRANS_BACK, Tween.EASE_OUT)
					else:
						tween.interpolate_property(frame, "translation:z", 1.5, 0, Conductor.get_seconds_per_beat() / 4.0, Tween.TRANS_BACK, Tween.EASE_OUT)
			
			tween.start()
			logo_anim_beats.pop_front()
	else:
		set_process(false)
