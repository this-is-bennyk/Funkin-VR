extends "res://scripts/game/characters/DoubleIdleCharacter.gd"

func play_anim(anim_data, anim_length = 0, forced = true, uninterruptable = false):
	.play_anim(anim_data, anim_length, forced)
	
	var anim_name = get_anim_name(anim_data)
	
	if anim_name == "Idle_Left" || anim_name == "Idle_Right":
		anim_player.playback_speed = Conductor.get_bpm() / 60.0 * Conductor.pitch_scale
		anim_player.update_playback_speed()
	else:
		anim_player.playback_speed = Conductor.pitch_scale
		anim_player.update_playback_speed()
