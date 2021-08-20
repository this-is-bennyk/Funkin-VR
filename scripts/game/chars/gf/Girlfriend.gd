extends Spatial

export(int) var week = 0

const ANIM_PAIRS = {
	"DanceFace": [
		"Dance_Left",
		"Dance_Right",
		"W3_Hair_Blow",
		"W3_Hair_Land",
		"W4_Dance_Left",
		"W4_Dance_Right"
	],
	"DuckFace": [
		"W4_Duck"
	],
	"IdleFace": [
		"Idle_Left",
		"Idle_Right"
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
	
	match week:
		4:
			anim_to_play = "W4_Dance_Right"
	
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
		match week:
			4:
				anim_to_play = "W4_Dance_Left"
			_:
				anim_to_play = "Dance_Left"
	else:
		match week:
			4:
				anim_to_play = "W4_Dance_Right"
			_:
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
