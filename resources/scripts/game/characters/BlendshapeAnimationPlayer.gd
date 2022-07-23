extends AnimationPlayer

const CRUMPLE_ANIM_NAME = "Crumple"

export(NodePath) var default_face_player_path
export(NodePath) var default_anim_player_path
export(NodePath) var gles2_face_path

onready var gles2_face = get_node_or_null(gles2_face_path)
onready var default_face_player = get_node_or_null(default_face_player_path)
onready var default_anim_player = get_node_or_null(default_anim_player_path)

func _ready():
	if !(gles2_face && default_anim_player && default_anim_player):
		return
	
	if OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES2:
		gles2_face.show()
		
		for anim_name in get_animation_list():
			var anim = get_animation(anim_name)
			anim.track_set_enabled(anim.find_track(get_parent().get_path_to(default_anim_player)), false)
		
		default_face_player.play(CRUMPLE_ANIM_NAME)
		
	else:
		gles2_face.hide()
