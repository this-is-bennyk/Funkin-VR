extends Character

func set_up_anim_info():
	anim_dicts = {
		"Idle": ["Idle", "IdleFace"],
		Conductor.Directions.LEFT: ["Left", "LeftFace"],
		Conductor.Directions.DOWN: ["Down", "DownFace"],
		Conductor.Directions.UP: ["Up", "UpFace"],
		Conductor.Directions.RIGHT: ["Right", "RightFace"],
		"Charm": ["Charm", "CharmFace"],
		"Duck": ["Duck", "DuckFace"]
	}
	
	anim_player_list = [$AnimationPlayer, $FacePlayer]
