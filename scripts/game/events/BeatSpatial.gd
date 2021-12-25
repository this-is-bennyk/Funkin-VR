extends Spatial

# note_to_hit: tells us which note to play animations on
export(Conductor.Notes) var note_to_hit = Conductor.Notes.QUARTER
# beat_interval: tells us to play an animation every n beats
export(int) var beat_interval = 1
export(String) var idle_anim_name = "Beat_Hit"

onready var anim_player = $AnimationPlayer

var bumping = true

func _ready():
	var signal_to_connect
	
	match note_to_hit:
		Conductor.Notes.QUARTER:
			signal_to_connect = "quarter"
		Conductor.Notes.EIGHTH:
			signal_to_connect = "eighth"
		Conductor.Notes.SIXTEENTH:
			signal_to_connect = "sixteenth"
	
	signal_to_connect += "_hit"
	
	Conductor.connect(signal_to_connect, self, "on_beat_hit")

func on_beat_hit(beat):
	if bumping && beat % beat_interval == 0:
		anim_player.stop()
		anim_player.play(idle_anim_name)
