extends Spatial

export(int) var week = 0

const ANIM_PAIRS = {
	"DanceFace": [
		"Dance_Left",
		"Dance_Right"
	]
}

onready var anim_player: AnimationPlayer = $AnimationPlayer
onready var face_player: AnimationPlayer = $FacePlayer

var dancing = false
var danced_right = false
var beats_to_hit = 1

# TODO: When week 2 and beyond exist...

func _ready():
	on_ready()

func on_ready():
	var anim_to_play = "Dance_Right"
	
	anim_player.play(anim_to_play)
	anim_player.stop()
	anim_player.seek(0, true)
	
	face_player.play("DanceFace")
	anim_player.stop()
	anim_player.seek(0, true)
	
	Conductor.connect("quarter_hit", self, "on_quarter_hit")

func start():
	danced_right = false
	dance()
	dancing = true

func stop():
	anim_player.stop()
	face_player.stop()
	
	dancing = false

func on_quarter_hit(quarter):
	if dancing && int(quarter) % beats_to_hit == 0:
		dance()

func dance():
	var anim_to_play
	
	if danced_right:
		anim_to_play = "Dance_Left"
	else:
		anim_to_play = "Dance_Right"
	
	play_anim(anim_to_play)
	
	danced_right = !danced_right

func play_anim(anim_name):
	var face_name
	
	for key in ANIM_PAIRS.keys():
		if anim_name in ANIM_PAIRS[key]:
			face_name = key
			break
	
	if !face_name:
		face_name = anim_name + "Face"
	
	anim_player.stop()
	anim_player.play(anim_name)
	
	face_player.stop()
	face_player.play(face_name)
