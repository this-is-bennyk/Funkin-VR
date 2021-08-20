extends Character

func set_up_anim_info():
	anim_player_list = [$AnimationPlayer]
	
	anim_dicts = {
		"Idle": ["Idle"],
		Conductor.Directions.LEFT: ["Left"],
		Conductor.Directions.DOWN: ["Down"],
		Conductor.Directions.UP: ["Up"],
		Conductor.Directions.RIGHT: ["Right"],
		"W3_Preparing": ["W3_Preparing"],
		"W3_Shooting": ["W3_Shooting"]
	}
