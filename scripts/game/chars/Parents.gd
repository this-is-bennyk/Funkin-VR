extends Character

var moms_turn = false

func set_up_anim_info():
	anim_dicts = {
		"Idle": ["Idle", "IdleFaceD", "IdleFaceM"],
		Conductor.Directions.LEFT: ["Left", "LeftFaceD", "LeftFaceM"],
		Conductor.Directions.DOWN: ["Down", "DownFaceD", "DownFaceM"],
		Conductor.Directions.UP: ["Up", "UpFaceD", "UpFaceM"],
		Conductor.Directions.RIGHT: ["Right", "RightFaceD", "RightFaceM"]
	}
	
	anim_player_list = [$AnimationPlayer, $FacePlayerD, $FacePlayerM]

func _sync_anim_players(anim):
	stop_anim_players(false)
	
	var cur_anim_dict = anim_dicts[anim]
	
	for i in len(anim_player_list):
		if i == 1 && moms_turn:
			anim_player_list[i].play("IdleFaceD")
		elif i == 2 && !moms_turn:
			anim_player_list[i].play("IdleFaceM")
		else:
			anim_player_list[i].play(cur_anim_dict[i])
