extends AnimationTree

const CRUMPLE_ANIM_NAME = "Crumple"
const LOOP_SUFFIX = "_Loop"
const DEFAULT_G2F_TO_A_MAP = {
	"IdleFace": ["Idle"],
	"DownFace": ["Down"],
	"LeftFace": ["Left"],
	"RightFace": ["Right"],
	"UpFace": ["Up"]
}

export(float) var playback_speed: float = 1
export(NodePath) var gles2_face_path
export(NodePath) var gles2_face_anim_path
export(Dictionary) var gles2_face_to_anim_map: Dictionary = DEFAULT_G2F_TO_A_MAP
export(Dictionary) var anim_name_remap: Dictionary = {}

onready var playback: AnimationNodeStateMachinePlayback = get("parameters/playback")
onready var gles2_face = get_node(gles2_face_path)
onready var gles2_face_anim = get_node(gles2_face_anim_path)

var _cur_anim = ""

func _ready():
	if OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES2:
		gles2_face.show()
	else:
		gles2_face.hide()

func _process(delta):
	var is_looping_anim = playback.get_current_node().ends_with(LOOP_SUFFIX)
	
	if is_looping_anim && (playback.get_current_play_position() >= playback.get_current_length()):
		play(playback.get_current_node())

func play(anim_name):
	if anim_name in anim_name_remap:
		anim_name = anim_name_remap[anim_name]
	
	set("parameters/" + anim_name + "/TimeScale/scale", playback_speed)
	
	if OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES2:
		set("parameters/" + anim_name + "/FaceEnabler/add_amount", 0)
		print("GF's face disappears")
		
		for face_name in gles2_face_to_anim_map.keys():
			if gles2_face_to_anim_map[face_name].has(anim_name):
				gles2_face_anim.stop()
				gles2_face_anim.play(face_name)
				break
	
	playback.start(anim_name)
	_cur_anim = anim_name

func stop():
	playback.stop()

func has_animation(anim_name):
	return tree_root.has_node(anim_name)

func update_playback_speed():
	set("parameters/" + _cur_anim + "/TimeScale/scale", playback_speed)
