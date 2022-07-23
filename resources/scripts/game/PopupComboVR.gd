extends Spatial

onready var rating = $Rating
onready var combo_nums = [$ComboNum_Ones, $ComboNum_Tens, $ComboNum_Hundreds]
onready var tween = $Tween

var rating_idx = 0
var combo = 0

var rating_velocity = Vector3()
var rating_y_accel = 550 / 100.0
var rating_z_accel = 300 / 100.0

var combo_num_velocities = []
var combo_num_y_accels = []
var combo_num_z_accels = []

func _ready():
	var half_frame_width = rating.frames.get_frame("default", rating_idx).get_width() * rating.scale.x / 2.0 / 100.0
	
	rating.frame = rating_idx
	rating_velocity = Vector3(-flx_randi(0, 10) / 100.0, -flx_randi(140, 175) / 100.0, -flx_randi(0, 10) / 100.0)
	tween.interpolate_property(rating, "modulate:a", 1, 0, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, Conductor.get_seconds_per_beat())
	
	for combo_num_idx in len(combo_nums):
		combo_nums[combo_num_idx].frame = int(combo / pow(10, combo_num_idx)) % 10
		combo_nums[combo_num_idx].translation.x = -half_frame_width - (50 / 100.0) + ((43 / 100.0) * (len(combo_nums) - 1 - combo_num_idx))
		combo_num_velocities.append(Vector3(rand_range(-5 / 100.0, 5 / 100.0), -flx_randi(140, 160) / 100.0, rand_range(-5 / 100.0, 5 / 100.0)))
		combo_num_y_accels.append(flx_randi(200, 300) / 100.0)
		combo_num_z_accels.append(flx_randi(200, 300) / 100.0)
		tween.interpolate_property(combo_nums[combo_num_idx], "modulate:a", 1, 0, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, Conductor.get_seconds_per_beat() * 2)
	
	tween.connect("tween_completed", self, "on_tween_completed", [], CONNECT_DEFERRED)
	tween.start()

func _process(delta):
	rating_velocity.y += rating_y_accel * delta
	rating_velocity.z -= rating_z_accel * delta
	rating.translation += rating_velocity * Vector3(1, -1, 1) * delta
	
	for combo_num_idx in len(combo_nums):
		combo_num_velocities[combo_num_idx].y += combo_num_y_accels[combo_num_idx] * delta
		combo_num_velocities[combo_num_idx].z -= combo_num_z_accels[combo_num_idx] * delta
		combo_nums[combo_num_idx].translation += combo_num_velocities[combo_num_idx] * Vector3(1, -1, 1) * delta

func on_tween_completed(obj, _key):
	if obj in combo_nums:
		for connection in tween.get_signal_connection_list("tween_completed"):
			connection.source.disconnect(connection.signal, connection.target, connection.method)
		queue_free()

func flx_randi(min_, max_):
	var inclusive_range = max_ - min_ + 1
	return randi() % inclusive_range + min_
