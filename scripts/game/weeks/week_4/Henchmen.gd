extends "res://scripts/game/events/BeatSpatial.gd"

var danced_left = false

func on_beat_hit(beat):
	if bumping && beat % beat_interval == 0:
		var anim_name = "Dance_Right" if danced_left else "Dance_Left"
		$AnimationPlayer.play(anim_name)
		danced_left = !danced_left
