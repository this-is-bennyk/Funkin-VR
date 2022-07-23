extends "res://packages/fnfvr/resources/scripts/game/levels/LevelVR.gd"

const SHOOT_GAME_OVER = preload("res://packages/fnfvr/resources/scenes/game/game_over/GameOverVR_PicoShoot.tscn")
const WARNING_SIGNS = [
	preload("res://packages/fnfvr/resources/graphics/game/levels/week_3/pico_sign_duck.png"),
	preload("res://packages/fnfvr/resources/graphics/game/levels/week_3/pico_sign_left.png"),
	preload("res://packages/fnfvr/resources/graphics/game/levels/week_3/pico_sign_right.png")
]

const DUCK_HEIGHT_PERCENT = 0.85
const SHOOT_PENALTIES = [0.5, 2 / 3.0, 1]

enum TrainStates {NOT_MOVING, APPROACHING, PASSING}
enum ShootStates {NOT_SHOOTING, AIMING}
enum ActionStates {DUCK, LEFT, RIGHT}

onready var train_passing_noise = $Train_Pass_Noise
onready var train_cooldown = $Train_Cooldown
onready var train_event_timer = $Train_Event_Timer
onready var train_anim = $Train_Station/AnimationPlayer

onready var aim_timer = $Aim_Timer
onready var aim_anim_timer = $Aim_Anim_Timer
onready var warning_sign = $Warning_Sign
onready var warning_sign_anim = $Warning_Sign/AnimationPlayer
onready var shoot_noise = $Shoot_Noise
onready var world_env_anim = $WorldEnvironment/AnimationPlayer

var train_passing = false
var shooting = false

func do_train_pass(past_state):
	match past_state:
		TrainStates.NOT_MOVING:
			if randf() <= 0.3 && !train_passing && !train_passing_noise.playing && train_cooldown.time_left == 0:
				train_cooldown.start(Conductor.get_seconds_per_beat() * (9 + randi() % 4) / Conductor.pitch_scale)
				
				train_passing = true
				train_passing_noise.play()
				
				train_event_timer.start(4.7 / Conductor.pitch_scale)
				train_event_timer.connect("timeout", self, "do_train_pass", [TrainStates.APPROACHING], CONNECT_DEFERRED | CONNECT_ONESHOT)
		
		TrainStates.APPROACHING:
			train_anim.play("Train_Pass")
			
			get_performer("metronome").play_anim("W3_Hair_Blow_Loop", 2.0 / Conductor.pitch_scale)
			
			train_event_timer.start(1.8 / Conductor.pitch_scale)
			train_event_timer.connect("timeout", self, "do_train_pass", [TrainStates.PASSING], CONNECT_DEFERRED | CONNECT_ONESHOT)
		
		TrainStates.PASSING:
			train_passing = false
			get_performer("metronome").play_anim("W3_Hair_Land", 0.5 / Conductor.pitch_scale)
			get_performer("metronome").danced_right = false
			
			train_event_timer.start(0.5 / Conductor.pitch_scale)

func do_pico_shoot(past_state, action_state):
	if UserData.get_setting("VR_mechanics", 1, "options", "fnfvr") == 0:
		return
	
	var pico = get_performer("opponent")
	
	match past_state:
		ShootStates.NOT_SHOOTING:
			print(Conductor.get_playback_position())
			if shooting:
				print("Already shooting!")
				return
			
			shooting = true
			
			warning_sign.material_override.albedo_texture = WARNING_SIGNS[action_state]
			warning_sign_anim.play("Flash")
			
			var seconds = 1.0 / Conductor.pitch_scale
			
			pico.play_anim("Aim", seconds, true, true)
			aim_anim_timer.start(seconds)
			aim_anim_timer.connect("timeout", pico, "play_anim", ["Shoot", seconds], CONNECT_DEFERRED | CONNECT_ONESHOT)
			
			aim_timer.start((1 + (4 / 24.0)) / Conductor.pitch_scale)
			aim_timer.connect("timeout", self, "do_pico_shoot", [ShootStates.AIMING, action_state], CONNECT_DEFERRED | CONNECT_ONESHOT)
		
		ShootStates.AIMING:
			shooting = false
			
			shoot_noise.stop()
			shoot_noise.play()
			pico.get_node("Pico Armature/Skeleton/Gun_Bone/Gun_Flash").restart()
			
			var hit = false
			
			match action_state:
				ActionStates.LEFT:
					# Hit if the player is to the right
					hit = main.player.headset_camera.translation.x >= 0
				ActionStates.RIGHT:
					# Hit if the player is to the left
					hit = main.player.headset_camera.translation.x <= 0
				_: # ActionStates.DUCK
					# Hit if the player hasn't ducked their head far enough down
					hit = main.player.headset_camera.translation.y >= DUCK_HEIGHT_PERCENT * (1 / main.player.origin.scale.x)
			
			if (!hit) || Debug.botplay: # Real shit
#			if !hit: # DEBUG
				return
			
			world_env_anim.play("Hit_Flash")
			
			# DEBUG
#			if !main.player.origin.auto_initialise:
#				return
			
			var shoot_penalty = SHOOT_PENALTIES[get_parent().difficulty]
			
			if health - shoot_penalty <= 0:
				get_performer("player").death_scene = SHOOT_GAME_OVER
			
			update_health(-SHOOT_PENALTIES[get_parent().difficulty])
