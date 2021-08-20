class_name Character
extends Spatial

var anim_player_list = []
var anim_dicts: Dictionary = {}

var hold_time = 0
var sixteenths_to_hold = 4
var uninterrupted_anim = false

func _ready():
	on_ready()

func on_ready():
	set_up_anim_info()
	
	_sync_anim_players("Idle")
	stop_anim_players(true)
	
	set_process(false)
	Conductor.connect("quarter_hit", self, "on_quarter_hit")

func set_up_anim_info():
	anim_player_list = [$AnimationPlayer, $FacePlayer]
	
	anim_dicts = {
		"Idle": ["Idle", "IdleFace"],
		Conductor.Directions.LEFT: ["Left", "LeftFace"],
		Conductor.Directions.DOWN: ["Down", "DownFace"],
		Conductor.Directions.UP: ["Up", "UpFace"],
		Conductor.Directions.RIGHT: ["Right", "RightFace"]
	}

func start():
	idle()
	set_process(true)

func stop():
	stop_anim_players(false)
	set_process(false)

func _process(delta):
	if anim_player_list[0].assigned_animation.find("Idle") == -1:
		hold_time -= delta
	
		if hold_time <= 0:
			idle()

func on_quarter_hit(quarter):
	if hold_time == 0:
		idle()

func idle():
	_sync_anim_players("Idle")
	
	hold_time = 0
	uninterrupted_anim = false

func play_anim(anim, hold_or_sustain_time = 0, overriding_time = false, uninterrupted = false):
	if !uninterrupted_anim:
		_sync_anim_players(anim)
		
		if overriding_time:
			hold_time = hold_or_sustain_time
		else:
			hold_time = Conductor.get_sixteenth_length() * sixteenths_to_hold + hold_or_sustain_time
		
		uninterrupted_anim = uninterrupted

func stop_anim_players(do_init_seek):
	for anim_player in anim_player_list:
		anim_player.stop()
		
		if do_init_seek:
			anim_player.seek(0, true)

func _sync_anim_players(anim):
	stop_anim_players(false)
	
	var cur_anim_dict = anim_dicts[anim]
	
	for i in len(anim_player_list):
		anim_player_list[i].play(cur_anim_dict[i])
