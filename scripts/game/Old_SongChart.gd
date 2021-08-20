class_name Old_SongChart

var song
var vocals

var song_name = ""
var sections = []
var bpm = 100
var needs_vocals = true
var speed = 1

var player_1 = "bf"
var player_2 = "dad"

func _init(json_name, difficulty = ""):
	var file = File.new()
	
	file.open("res://assets/data/" + json_name + "/" + json_name + difficulty + ".json", File.READ)
	var parsed_song = JSON.parse(file.get_as_text()).result
	
	song_name = parsed_song.song
	sections = parsed_song.notes
	bpm = parsed_song.bpm
	needs_vocals = parsed_song.needsVoices
	
	if parsed_song.has("speed"):
		speed = parsed_song.speed
	
	song = load("res://assets/music/" + song_name + "_Inst.ogg")
	
	if needs_vocals:
		vocals = load("res://assets/music/" + song_name + "_Voices.ogg")
