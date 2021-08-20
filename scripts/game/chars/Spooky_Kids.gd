extends Character

var idle_speed = 150 / 60.0
var danced_right = false

func on_ready():
	set_up_anim_info()
	
	_sync_anim_players("Idle_Right")
	stop_anim_players(true)
	
	set_process(false)
	Conductor.connect("quarter_hit", self, "on_quarter_hit")

func set_up_anim_info():
	anim_player_list = [$AnimationPlayer, $FacePlayerS, $FacePlayerP]
	
	anim_dicts = {
		"Idle_Left": ["Idle_Left", "IdleFaceS", "IdleFaceP"],
		"Idle_Right": ["Idle_Right", "IdleFaceS", "IdleFaceP"],
		Conductor.Directions.LEFT: ["Left", "LeftFaceS", "LeftFaceP"],
		Conductor.Directions.DOWN: ["Down", "DownFaceS", "DownFaceP"],
		Conductor.Directions.UP: ["Up", "UpFaceS", "UpFaceP"],
		Conductor.Directions.RIGHT: ["Right", "RightFaceS", "RightFaceP"]
	}

func idle():
	if anim_player_list[0].playback_speed != idle_speed:
		for anim_player in anim_player_list:
			anim_player.playback_speed = idle_speed
	
	var anim_name = "Idle_Left" if danced_right else "Idle_Right"
	
	_sync_anim_players(anim_name)
	
	hold_time = 0
	danced_right = !danced_right

func play_anim(anim, hold_or_sustain_time = 0, overriding_time = false, uninterrupted = false):
	for anim_player in anim_player_list:
		anim_player.playback_speed = 1
	
	.play_anim(anim, hold_or_sustain_time, overriding_time, uninterrupted)
