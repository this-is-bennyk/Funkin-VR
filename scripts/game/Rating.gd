extends CPUParticles

func _ready():
	emitting = true
	yield(get_tree().create_timer(0.6), "timeout")
	queue_free()
