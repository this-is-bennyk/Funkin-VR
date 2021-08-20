extends Level

enum TrainStates {NOT_MOVING, APPROACHING, PASSING, LEAVING}
enum ShootingStates {NOT_SHOOTING, PREPARING, SHOOTING}
enum BlammedMovements {SQUAT, LTR_STRAFE, RTL_STRAFE}

onready var city_lights_mat = $Week_3_Stage/Bobbie/CityObjects/city2/Cube_6.mesh.surface_get_material(0)
onready var city_lights_mat_2 = $Week_3_Stage/Sayge/RootNode/Map.mesh.surface_get_material(1)

onready var warning_popup = $Warning_Popup
onready var shooting_noise = $Shooting_Noise

onready var train_cooldown = $Train_Cooldown
onready var train_event_timer = $Train_Event_Timer
onready var train_passing_noise = $Train_Passing
onready var train_anim = $Train_Anim
var train_passing = false

var city_light_colors = [
	Color("#31a2fd"),
	Color("#31fd8c"),
	Color("#fb33f5"),
	Color("#fd4531"),
	Color("#fba633")
]
var cur_city_light_color = 0

onready var preparing_timer = $Preparing_Timer
#var shoot_bf_beats = [32, 48, 64, 80, 104, 120, 160, 163, 165, 168, 171, 173, 200, 216, 224, 232, 240, 248, 256]
var shoot_bf_instructions = [
	[32, BlammedMovements.SQUAT],
	[48, BlammedMovements.LTR_STRAFE],
	[64, BlammedMovements.RTL_STRAFE],
	[80, BlammedMovements.LTR_STRAFE],
	[96, BlammedMovements.RTL_STRAFE],
	[104, BlammedMovements.SQUAT],
	[120, BlammedMovements.RTL_STRAFE],
	[128, BlammedMovements.LTR_STRAFE],
	[134, BlammedMovements.SQUAT],
	[138, BlammedMovements.SQUAT],
	[142, BlammedMovements.SQUAT],
	[160, BlammedMovements.LTR_STRAFE],
	[166, BlammedMovements.SQUAT],
	[174, BlammedMovements.SQUAT],
	[192, BlammedMovements.RTL_STRAFE],
	[200, BlammedMovements.SQUAT],
	[216, BlammedMovements.LTR_STRAFE],
	[224, BlammedMovements.RTL_STRAFE],
	[232, BlammedMovements.SQUAT],
	[240, BlammedMovements.RTL_STRAFE],
	[248, BlammedMovements.LTR_STRAFE],
	[256, BlammedMovements.SQUAT]
]

func on_ready():
	opponent = $Pico
	metronome = $Girlfriend
	
	opponent_icons_idx = 20
	
	async_event_func_names = ["do_train_pass", "shoot_boyfriend"]
	
	.on_ready()

func set_songs():
	if !song_json_names.empty():
		return
	
	song_json_names = ["pico", "philly", "blammed"]

func do_level_prep():
	repeating_events = [
		[
			4,
			8,
			Conductor.Notes.QUARTER,
			funcref(self, "do_train_pass"),
			[TrainStates.NOT_MOVING]
		],
		[
			0,
			4,
			Conductor.Notes.QUARTER,
			funcref(self, "flash_city_lights"),
			[]
		]
	]
	
	if songs[0].song_name == "Blammed":
		onetime_events = []
		var shoot_bf_func = funcref(self, "shoot_boyfriend")
		
		for idx in len(shoot_bf_instructions):
			onetime_events.append([
				shoot_bf_instructions[idx][0] - 2,
				Conductor.Notes.QUARTER,
				shoot_bf_func,
				[ShootingStates.NOT_SHOOTING, shoot_bf_instructions[idx][1]]
			])
	
	train_passing = false
	
	if !train_passing_noise: # If one of these necessary objects isn't initialized:
		yield(get_tree(), "idle_frame")
	
	train_passing_noise.stop()
	
	train_anim.stop()
	train_anim.seek(0, true)
	
	train_cooldown.start(Conductor.get_seconds_per_beat() * (9 + randi() % 4))

func do_level_cleanup():
	train_passing_noise.stop()
	train_anim.stop()
	
	warning_popup.hide()

func die(initial_call):
	if initial_call:
		do_level_cleanup()
	.die(initial_call)

func do_train_pass(past_state):
	match past_state:
		TrainStates.NOT_MOVING:
			if randf() <= 0.3 && !train_passing && !train_passing_noise.playing && train_cooldown.time_left == 0:
				train_cooldown.start(Conductor.get_seconds_per_beat() * (9 + randi() % 4))
				
				train_passing = true
				train_passing_noise.play()
				
				train_event_timer.start(4.7)
				train_event_timer.connect("timeout", self, "do_train_pass", [TrainStates.APPROACHING], CONNECT_DEFERRED | CONNECT_ONESHOT)
		
		TrainStates.APPROACHING:
			train_anim.play("Train_Pass")
			
			metronome.dancing = false
			metronome.play_anim("W3_Hair_Blow")
			
			train_event_timer.start(1.8)
			train_event_timer.connect("timeout", self, "do_train_pass", [TrainStates.PASSING], CONNECT_DEFERRED | CONNECT_ONESHOT)
		
		TrainStates.PASSING:
			train_passing = false
			metronome.play_anim("W3_Hair_Land")
			
			train_event_timer.start(7 / 24.0)
			train_event_timer.connect("timeout", self, "do_train_pass", [TrainStates.LEAVING], CONNECT_DEFERRED | CONNECT_ONESHOT)
		
		TrainStates.LEAVING:
			metronome.dancing = true
			metronome.danced_right = true

func flash_city_lights():
	city_lights_mat.albedo_color = city_light_colors[cur_city_light_color]
	city_lights_mat_2.set_shader_param("desired_color", city_light_colors[cur_city_light_color])
	
	var prev_color = cur_city_light_color
	cur_city_light_color = randi() % len(city_light_colors)
	
	while cur_city_light_color == prev_color:
		cur_city_light_color = randi() % len(city_light_colors)

func shoot_boyfriend(past_state, dodge_dir):
	match past_state:
		ShootingStates.NOT_SHOOTING:
			opponent.play_anim("W3_Preparing", Conductor.get_seconds_per_beat() * 2, true, true)
			
			warning_popup.show()
			
			var arrow_name = "Down"
			match dodge_dir:
				BlammedMovements.LTR_STRAFE:
					arrow_name = "Right"
				BlammedMovements.RTL_STRAFE:
					arrow_name = "Left"
			
			for child in warning_popup.get_children():
				if child.name == "AnimationPlayer":
					continue
				child.visible = arrow_name in child.name
			
			preparing_timer.start(Conductor.get_seconds_per_beat() * 2)
			preparing_timer.connect("timeout", self, "shoot_boyfriend", [ShootingStates.PREPARING, dodge_dir], CONNECT_ONESHOT)
		
		ShootingStates.PREPARING:
			warning_popup.hide()
			
			opponent.play_anim("W3_Shooting", 0, false, true)
			shooting_noise.play()
			
			get_tree().connect("idle_frame", self, "shoot_boyfriend", [ShootingStates.SHOOTING, dodge_dir], CONNECT_ONESHOT)
	
		ShootingStates.SHOOTING:
			var bf_safe_condition = false
			
			match dodge_dir:
				BlammedMovements.SQUAT:
					bf_safe_condition = Player.camera.global_transform.origin.y < 0.9
				BlammedMovements.LTR_STRAFE:
					bf_safe_condition = Player.camera.global_transform.origin.x > 0
				BlammedMovements.RTL_STRAFE:
					bf_safe_condition = Player.camera.global_transform.origin.x < 0
			
			if !bf_safe_condition:
				update_health(-1)
