extends MeshInstance

func _ready():
	if OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES2:
		material_override.flags_albedo_tex_force_srgb = false
