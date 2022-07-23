extends AnimationPlayer

func _ready():
	if OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES2:
		return
	play("Jitter")
