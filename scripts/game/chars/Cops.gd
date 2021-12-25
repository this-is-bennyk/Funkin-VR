extends "res://scripts/game/events/BeatSpatial.gd"

func on_beat_hit(beat):
	if bumping && beat % beat_interval == 0:
		anim_player.stop()
		anim_player.play(idle_anim_name)
		
		idle_anim_name = "Armature002Action" if idle_anim_name == "Bounce" else "Bounce"
