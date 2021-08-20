class_name Note
extends Spatial

signal ready_to_hit(dir, sustain_length)
signal good_hit(dir, note_diff, global_origin)
signal miss

signal opponent_hit(dir, sustain_length)

#const SCROLL_DISTANCE = 0.85 * 2 # units
const SCROLL_DISTANCE = 0.875 * 2 # units
const SCROLL_TIME = 0.6 * 2 # sec

# Aka PURPLE, BLUE, GREEN, RED
enum Directions {LEFT, DOWN, UP, RIGHT}

onready var tween: Tween = $Tween
var step_zone
var particles

#### Note Data #####################

var direction = Directions.LEFT

var strum_time = 0 # TODO: CONVERT FROM MSECS TO SECONDS DON'T FORGET!!!!!!!!!!!!
var must_press = false
var can_hit = false

var ready_to_hit = false
var moving = false

#### Note Graphics #################

onready var note_model = $Note_Model
onready var inner_mesh = $Note_Model/Inner/Mesh
onready var outer_mesh = $Note_Model/Outer/Mesh

# TODO: istg idk what I'm doing wrong for the down note. It should
# be exactly the goddamn same as the others, but it's not. WHY????????
var inner_material: SpatialMaterial
var outer_material: SpatialMaterial
var bright_color = Color("#12fa05")

func _ready():
	visible = false
	
	inner_mesh.material_override = inner_material
	outer_mesh.material_override = outer_material
	
	rotation.y = PI
	match direction:
		Directions.LEFT:
			note_model.rotation = Vector3(0, PI / 2, PI / 2)
		Directions.DOWN:
			note_model.rotation = Vector3(-PI / 2, PI / 2, PI / 2)
		Directions.RIGHT:
			note_model.rotation = Vector3(0, -PI / 2, -PI / 2)
	
	if OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES2:
		particles = $Particles_GLES2
		$Particles.queue_free()
		
		var mesh_mat = particles.mesh.surface_get_material(0).duplicate()
		mesh_mat.albedo_color = bright_color
		particles.mesh.surface_set_material(0, mesh_mat)
	
	else:
		particles = $Particles
		$Particles_GLES2.queue_free()
		
		var mesh_mat = particles.draw_pass_1.surface_get_material(0).duplicate()
		mesh_mat.albedo_color = bright_color
		particles.draw_pass_1.surface_set_material(0, mesh_mat)
	
	tween.connect("tween_completed", self, "_on_tween_completed")

func _process(delta):
	on_process(delta)

func on_process(delta):
	# If the song is at or beyond the desired strum time, start moving
	# (This has to be to done to prevent notes from arriving too early)
	
	if !moving && Conductor.song_position >= strum_time - SCROLL_TIME / Conductor.scroll_speed:
		start_moving()
	
	# If the note is within the lane, appear
	
	if ((must_press && translation.z <= 2) || (!must_press && translation.y >= -2)) && !visible:
		make_visible()

	if must_press:
		player_process(delta)
	else:
		opponent_process(delta)

func start_moving():
	if must_press:
		tween.interpolate_property(self, "translation:z", SCROLL_DISTANCE * Conductor.scroll_speed, \
														  0, \
														  SCROLL_TIME / Conductor.scroll_speed)
	else:
		tween.interpolate_property(self, "translation:y", -SCROLL_DISTANCE * Conductor.scroll_speed, \
														  0, \
														  SCROLL_TIME / Conductor.scroll_speed)
	
	tween.start()
	moving = true

func make_visible():
	visible = true
	particles.emitting = true

func player_process(delta):
	# Check to see if we can hit the note / we missed it
	
	if Conductor.song_position > strum_time - Conductor.SAFE_ZONE * 1.5 && !ready_to_hit:
		emit_signal("ready_to_hit", direction, 0)
		ready_to_hit = true
	
	if within_safe_zone():
		can_hit = true
	else:
		can_hit = false

		if Conductor.song_position > strum_time + Conductor.SAFE_ZONE:
			emit_signal("miss")
			set_process(false)
			
			yield(get_tree().create_timer(SCROLL_TIME / Conductor.scroll_speed - Conductor.SAFE_ZONE), "timeout")
			queue_free()
	
	# Check to see if we hit the note when we're supposed to
	
	if can_hit:
		var hit_condition = step_zone.lanes[direction].just_pressed
		
		if hit_condition:
			emit_signal("good_hit", direction, abs(strum_time - Conductor.song_position), global_transform.origin)
			
			set_process(false)
			queue_free()

func opponent_process(delta):
	if Conductor.song_position >= strum_time:
		emit_signal("opponent_hit", direction, 0)
		
		set_process(false)
		queue_free()

# Would make this a setget var if they didn't suck ass in Godot 3
func within_safe_zone():
	return Conductor.song_position > strum_time - Conductor.SAFE_ZONE * 0.5 && \
		   Conductor.song_position < strum_time + Conductor.SAFE_ZONE

func _on_tween_completed(obj, key):
	if must_press:
		tween.interpolate_property(self, "translation:z", translation.z, \
														  translation.z - SCROLL_DISTANCE * Conductor.scroll_speed, \
														  SCROLL_TIME / Conductor.scroll_speed)
	else:
		tween.interpolate_property(self, "translation:y", translation.y, \
														  translation.y + SCROLL_DISTANCE * Conductor.scroll_speed, \
														  SCROLL_TIME / Conductor.scroll_speed)
	tween.start()
