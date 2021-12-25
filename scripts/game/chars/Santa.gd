extends "res://scripts/game/events/BeatSpatial.gd"

var sweat_particles

func _ready():
	if OS.get_name() == "Android":
		sweat_particles = $Sweat_GLES2
		$Sweat.queue_free()
	else:
		sweat_particles = $Sweat
		$Sweat_GLES2.queue_free()

func on_beat_hit(beat):
	if bumping && beat % beat_interval == 0:
		anim_player.stop()
		anim_player.play(idle_anim_name)
		sweat_particles.restart()
