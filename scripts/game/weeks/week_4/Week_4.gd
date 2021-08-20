extends Level

enum LampPostState {APPROACHING, HITTING}
enum CharmState {KISSING, SPAWNING, PROCESSING, EXPLODING, EXPLODED}

const UNITS_TRAVELED_PER_SEC = 124.3632
const ROAD_START = 0.18

const PLAYER_DUCK_TIME_OFFSET = 2.44
const MOM_DUCK_TIME_OFFSET = 2.33
const MOM_FULL_DUCK_OFFSET = 0.4

const HEART_MESH_LOCAL_POSITION = Vector3(0, -0.048, 0.064)
const HEART_START_POS = Vector3(0.077, 1.032, -2.789)
const HEART_FINAL_POS = Vector3(0, 0.9, -0.15)
const HEART_X_VARIATION = 0.25
const HEART_SIZE = Vector3(0.397, 0.382, 0.598)
const HEART_SCALE = 0.5
const KISS_TIME_OFFSET = 0.53

var animate_road = true

onready var cars = [
	$Cars/Car1,
	$Cars/Car2,
	$Cars/Car3
]
onready var road = $FNFWeek4FBX/RootNode/FNFWeek4FBX/Road

onready var warning_popup = $Warning_Popup

onready var player_lamp_post_anim = $Lamp_Posts/Player_Post_Anim
onready var player_lamp_post_delay_timer = $Lamp_Posts/Player_Post_Delay_Timer
onready var mom_duck_delay_timer = $Lamp_Posts/Mom_Duck_Delay_Timer
onready var player_lamp_post_timer = $Lamp_Posts/Player_Post_Timer

onready var henchmen_lamp_post_anim = $Lamp_Posts/Dumb_Post_Anim

onready var heart_note = $Heart_Note
onready var charm_init_timer = $Charm_Init_Timer
onready var charm_move_tween = $Charm_Move_Tween
onready var charm_explode_timer = $Charm_Explode_Timer
var heart_note_aabb = AABB(HEART_START_POS, HEART_SIZE * HEART_SCALE)

var charm_strength = 0

var lamp_post_beats = {
	"High": [23, 39, 55, 71, 87, 103, 119, 135, 151, 167],
#	"Milf": [23, 39, 55, 71]
	"Milf": []
}

var charm_beats = [3, 36, 68, 98, 132, 164, 196, 228, 292, 324, 340, 356]

func on_ready():
	opponent = $Mom
	metronome = $Girlfriend
	
	opponent_icons_idx = 25
	
	async_event_func_names = ["hit_player_with_lamppost", "do_charm_event"]
	
	.on_ready()

func set_songs():
	if !song_json_names.empty():
		return
	
	song_json_names = ["satin-panties", "high", "milf"]

func set_video_driver_stuff():
	if OS.get_name() == "Android":
		$Henchmen/Ouch_Ptcls.queue_free()
		$Henchmen/Ouch_Ptcls2.queue_free()
		$Henchmen/Ouch_Ptcls3.queue_free()
		$Henchmen/Ouch_Ptcls4.queue_free()
		
		$Henchmen/Pain_Particles.queue_free()
		$Henchmen/Pain_Particles2.queue_free()
		$Henchmen/Pain_Particles3.queue_free()
		$Henchmen/Pain_Particles4.queue_free()
		
		$Henchmen/Revive_Particles.queue_free()
		$Henchmen/Revive_Particles2.queue_free()
		$Henchmen/Revive_Particles3.queue_free()
		$Henchmen/Revive_Particles4.queue_free()
		
		$Heart_Note/Spawn_Particles.queue_free()
		$Heart_Note/Swirly_Hearts.queue_free()
		$Heart_Note/Explosion_Hearts.queue_free()
	else:
		$Henchmen/Ouch_Ptcls_GLES2.queue_free()
		$Henchmen/Ouch_Ptcls_GLES2_2.queue_free()
		$Henchmen/Ouch_Ptcls_GLES2_3.queue_free()
		$Henchmen/Ouch_Ptcls_GLES2_4.queue_free()
		
		$Henchmen/Pain_Particles_GLES2.queue_free()
		$Henchmen/Pain_Particles_GLES2_2.queue_free()
		$Henchmen/Pain_Particles_GLES2_3.queue_free()
		$Henchmen/Pain_Particles_GLES2_4.queue_free()
		
		$Henchmen/Revive_Particles_GLES2.queue_free()
		$Henchmen/Revive_Particles_GLES2_2.queue_free()
		$Henchmen/Revive_Particles_GLES2_3.queue_free()
		$Henchmen/Revive_Particles_GLES2_4.queue_free()
		
		$Heart_Note/Spawn_Particles_GLES2.queue_free()
		$Heart_Note/Spawn_Particles_GLES2.queue_free()
		$Heart_Note/Explosion_Hearts_GLES2.queue_free()

func do_level_prep():
	repeating_events = [
		[
			0,
			1,
			Conductor.Notes.QUARTER,
			funcref(self, "zoom_car"),
			[]
		]
	]
	
	if songs[0].song_name != "Satin-Panties":
		repeating_events.append([
			8,
			16,
			Conductor.Notes.QUARTER,
			funcref(self, "kill_henchmen"),
			[]
		])
		
#		var seconds_per_beat = 60.0 / songs[0].bpm
#		var lamp_beat_array = lamp_post_beats[songs[0].song_name]
#		var player_lamp_func = funcref(self, "hit_player_with_lamppost")
#
#		onetime_events = []
#		for beat in lamp_beat_array:
#			onetime_events.append(
#				[
#					seconds_per_beat * beat - PLAYER_DUCK_TIME_OFFSET,
#					-1,
#					player_lamp_func,
#					[LampPostState.APPROACHING, beat == lamp_beat_array[0]]
#				])
#
#		if songs[0].song_name == "Milf":
#			charm_strength = 0
#
#			var charm_func = funcref(self, "do_charm_event")
#
#			for beat in charm_beats:
#				onetime_events.append([
#					seconds_per_beat * beat - KISS_TIME_OFFSET,
#					-1,
#					charm_func,
#					[CharmState.KISSING]
#				])
	
	if cars:
		for car in cars:
			car.get_node("AnimationPlayer").stop()
			car.get_node("AnimationPlayer").seek(0, true)
			
			$Cars.get_node(car.name + "_Sound").stop()
	
	if henchmen_lamp_post_anim:
		henchmen_lamp_post_anim.stop()
		henchmen_lamp_post_anim.seek(0, true)

func on_update(delta):
#	if songs[0].song_name == "Milf" && charm_strength < 0:
#		update_health(delta * charm_strength)
	
	.on_update(delta)
	
	if animate_road:
		update_road(delta)

func update_road(delta):
	road.translation.x = wrapf(road.translation.x - UNITS_TRAVELED_PER_SEC * delta, 
							   ROAD_START - (UNITS_TRAVELED_PER_SEC * 0.1), ROAD_START + (UNITS_TRAVELED_PER_SEC * 0.1))

func zoom_car():
	if (cars[0].get_node("AnimationPlayer").is_playing() && \
		cars[1].get_node("AnimationPlayer").is_playing() && \
		cars[2].get_node("AnimationPlayer").is_playing()) || randf() > 0.1:
		return
	
	var rand_car = randi() % cars.size()
	while cars[rand_car].get_node("AnimationPlayer").is_playing():
		rand_car = randi() % cars.size()
	
	cars[rand_car].get_node("RootNode/Cube004").get_active_material(1).albedo_color = Color.from_hsv(randf(), rand_range(0.8, 1.0), rand_range(0.8, 1.0), 1.0)
	cars[rand_car].get_node("AnimationPlayer").play("Car_Pass_" + str(randi() % 2))

func kill_henchmen():
	if !henchmen_lamp_post_anim.is_playing() && randf() <= 0.4:
		if OS.get_name() == "Android":
			henchmen_lamp_post_anim.play("Lamp_Hit_GLES2")
		else:
			henchmen_lamp_post_anim.play("Lamp_Hit")

# mom is mostly ducked at around 0.4s into her anim

func hit_player_with_lamppost(state, first_time = false):
	match state:
		LampPostState.APPROACHING:
			player_lamp_post_anim.play("Lamp_Hit")
			
			player_lamp_post_delay_timer.start(PLAYER_DUCK_TIME_OFFSET)
			player_lamp_post_delay_timer.connect("timeout", self, "hit_player_with_lamppost", [LampPostState.HITTING], CONNECT_DEFERRED | CONNECT_ONESHOT)
			
			mom_duck_delay_timer.start(MOM_DUCK_TIME_OFFSET - MOM_FULL_DUCK_OFFSET)
			mom_duck_delay_timer.connect("timeout", opponent, "play_anim", ["Duck", 1.5, true, true], CONNECT_DEFERRED | CONNECT_ONESHOT)
			
			show_warning(true, first_time)
		
		LampPostState.HITTING:
			hide_warning()
			
			if Player.camera.global_transform.origin.y >= 0.9:
				update_health(0, true)

func do_charm_event(state):
	match state:
		CharmState.KISSING:
			heart_note.global_transform.origin = HEART_START_POS
			
			opponent.play_anim("Charm", 1.5, true, true)
			
			charm_init_timer.connect("timeout", self, "do_charm_event", [CharmState.SPAWNING], CONNECT_DEFERRED | CONNECT_ONESHOT)
			charm_init_timer.start()
		
		CharmState.SPAWNING:
			heart_note.get_node("Spawn_Particles" + Settings.driver_suffix).restart()
			
			heart_note.get_node("Cube001").show()
			heart_note.get_node("Cube001").translation = HEART_MESH_LOCAL_POSITION
			heart_note.get_node("Cube001").scale = Vector3(3.75, 3.75, 3.75)
			
			heart_note.get_node("Swirly_Hearts" + Settings.driver_suffix).emitting = true
			heart_note.get_node("Swirly_Hearts" + Settings.driver_suffix).translation = Vector3()
			
			charm_move_tween.interpolate_property(heart_note, "global_transform:origin",
											  HEART_START_POS, HEART_FINAL_POS + Vector3(HEART_X_VARIATION * (randi() % 3 - 1), 0, 0),
											  Conductor.get_seconds_per_beat() * 4, Tween.TRANS_QUAD, Tween.EASE_IN)
			charm_move_tween.connect("tween_all_completed", self, "do_charm_event", [CharmState.EXPLODING], CONNECT_DEFERRED | CONNECT_ONESHOT)
			charm_move_tween.start()
			
			show_warning(false)
			
			get_tree().connect("idle_frame", self, "do_charm_event", [CharmState.PROCESSING], CONNECT_DEFERRED | CONNECT_ONESHOT)
		
		CharmState.PROCESSING:
			if charm_move_tween.is_active():
				var move_time = charm_move_tween.tell() / Conductor.get_seconds_per_beat() * 4
				var offset = Vector3(0.1 * cos(move_time), 0.1 * sin(move_time), 0)
				
				heart_note.get_node("Cube001").translation = HEART_MESH_LOCAL_POSITION + offset
				heart_note.get_node("Swirly_Hearts" + Settings.driver_suffix).translation = offset
			
			heart_note_aabb.position = heart_note.get_node("Cube001").global_transform.origin - heart_note_aabb.size
			
			if heart_note_aabb.has_point(Player.left_hand.global_transform.origin) || \
			   heart_note_aabb.has_point(Player.right_hand.global_transform.origin):
				print("hit")
				
				clear_event_signals(["do_charm_event"])
				
				charm_move_tween.stop_all()
				heart_note.get_node("AnimationPlayer").stop()
				
				heart_note.get_node("Cube001").hide()
				heart_note.get_node("Swirly_Hearts").emitting = false
				heart_note.get_node("Spawn_Particles" + Settings.driver_suffix).restart()
				
				hide_warning()
			else:
				get_tree().connect("idle_frame", self, "do_charm_event", [CharmState.PROCESSING], CONNECT_DEFERRED | CONNECT_ONESHOT)
		
		CharmState.EXPLODING:
			hide_warning()
			clear_event_signals(["do_charm_event"])
			
			heart_note.get_node("AnimationPlayer").play("Explosion" + Settings.driver_suffix)
			
			charm_explode_timer.connect("timeout", self, "do_charm_event", [CharmState.EXPLODED], CONNECT_DEFERRED | CONNECT_ONESHOT)
			charm_explode_timer.start()
		
		CharmState.EXPLODED:
			heart_note.get_node("Cube001").hide()
			
			charm_strength -= 0.025

func show_warning(is_ducking, first_time = false):
	if is_ducking:
		warning_popup.get_node("Duck").visible = first_time
		warning_popup.get_node("Icon").visible = !first_time
		warning_popup.get_node("Arrow").show()
		warning_popup.get_node("Touch").hide()
	else:
		warning_popup.get_node("Duck").hide()
		warning_popup.get_node("Icon").hide()
		warning_popup.get_node("Arrow").hide()
		warning_popup.get_node("Touch").show()
	
	warning_popup.get_node("AnimationPlayer").play("Warning_Flash")

func hide_warning():
	warning_popup.get_node("AnimationPlayer").stop()
	warning_popup.hide()
