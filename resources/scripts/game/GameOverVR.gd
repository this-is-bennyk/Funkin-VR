extends Spatial

enum DeathState {START, LOOP, END, QUIT}

export(NodePath) var loss_sfx_path
export(NodePath) var end_sfx_path
export(NodePath) var cancel_sfx_path

export(AudioStream) var death_music = preload("res://assets/music/gameOver.ogg")
export(float) var death_music_bpm = 100

onready var main = get_tree().root.get_node("Main")

onready var loss_sfx = get_node(loss_sfx_path)
onready var end_sfx = get_node(end_sfx_path)
onready var cancel_sfx = get_node(cancel_sfx_path)

onready var cloud_path = $Scene/Cloud_Path
onready var death_scene_anim = $Scene/AnimationPlayer
onready var fade_anim = $WorldEnvironment/AnimationPlayer
onready var mic = $Scene/Mic
onready var mic_tween = $Scene/Mic/Tween
onready var mic_crack_particles = $Scene/Crack_Particles
onready var display_obb = $MenuVR/Display/OBB

func _ready():
	mic.global_transform.origin = main.player.right_controller.global_transform.origin
	mic_crack_particles.global_transform.origin = mic.global_transform.origin
	
	death_scene_anim.assigned_animation = "Death_Start"
	death_scene_anim.seek(0, true)
	
	call_deferred("advance_death_state", DeathState.START)

func _process(delta):
	cloud_path.curve.set_point_position(0, main.player.headset_camera.global_transform.origin)

func _input(event):
	if event.is_action_released("ui_accept"):
		_advance_to_end()
		set_process_input(false)
	elif event.is_action_released("ui_cancel"):
		_advance_to_quit()
		set_process_input(false)

func advance_death_state(state):
	match state:
		DeathState.START:
			death_scene_anim.play("Death_Start")
			
			mic_tween.interpolate_property(mic, "global_transform:origin", mic.global_transform.origin, mic.global_transform.origin * Vector3(1, 0, 1), 11 / 24.0, Tween.TRANS_QUAD, Tween.EASE_IN, 14 / 24.0)
			mic_tween.start()
			
			loss_sfx.play()

		DeathState.LOOP:
			Conductor.play_music(death_music, death_music_bpm)

		DeathState.END:
			display_obb.disabled = true
			
			loss_sfx.stop()
			end_sfx.play()
			
			death_scene_anim.stop()
			death_scene_anim.play("Death_Confirm")
			fade_anim.play("Fade")
			Conductor.stop_song()

			get_tree().create_timer(2.2).connect("timeout", main.player, "play_transition", ["Basic_Fade_Out"], CONNECT_ONESHOT)
			get_tree().create_timer(2.7).connect("timeout", get_parent(), "restart", [], CONNECT_DEFERRED | CONNECT_ONESHOT)

		DeathState.QUIT:
			display_obb.disabled = true
			
			loss_sfx.stop()
			cancel_sfx.play()
			
			death_scene_anim.stop()
			Conductor.stop_song()

			main.player.connect("transition_finished", self, "_quit",  [], CONNECT_DEFERRED | CONNECT_ONESHOT)
			main.player.play_transition("Basic_Fade_Out")

func _advance_to_loop():
	advance_death_state(DeathState.LOOP)
func _advance_to_end():
	advance_death_state(DeathState.END)
func _advance_to_quit():
	advance_death_state(DeathState.QUIT)

func _quit(_trans_name):
	get_parent().quit_to_menu()
