extends Sprite3D

onready var tween = $Tween

var last_beat = 0

func _process(delta):
	if Conductor.get_quarter(true) != last_beat:
		tween.stop_all()
#		if fmod(Conductor.get_quarter(true), 2) == 0:
#			tween.interpolate_property(self, "scale:x", 1.2, 1, Conductor.get_seconds_per_beat() / 2)
#			tween.interpolate_property(self, "scale:y", 1.2, 1, Conductor.get_seconds_per_beat() / 2, Tween.TRANS_BACK, Tween.EASE_IN)
#		else:
#			tween.interpolate_property(self, "scale:x", 1.2, 1, Conductor.get_seconds_per_beat() / 2, Tween.TRANS_BACK, Tween.EASE_IN)
#			tween.interpolate_property(self, "scale:y", 1.2, 1, Conductor.get_seconds_per_beat() / 2)
		
		tween.interpolate_property(self, "scale:x", 1.2, 1, Conductor.get_seconds_per_beat() / 2, Tween.TRANS_BACK, Tween.EASE_IN)
		tween.interpolate_property(self, "scale:y", 1.2, 1, Conductor.get_seconds_per_beat() / 2, Tween.TRANS_BACK, Tween.EASE_IN)
		
		tween.start()
		
		last_beat = Conductor.get_quarter(true)
