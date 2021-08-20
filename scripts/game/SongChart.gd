class_name SongChart

enum ChartType {SNIFF, FNFVR}

var json_name
var category
var extension
var chart_type

var song
var vocals

var song_name = ""
var sections = []
var bpm = 100
var needs_vocals = true
var speed = 1

var player_1 = "bf"
var player_2 = "dad"

func _init(json_name_, difficulty = "", category_ = "fnf", extension_ = "ogg", chart_type_ = ChartType.SNIFF):
	json_name = json_name_
	category = category_
	extension = extension_
	chart_type = chart_type_
	
	var file = File.new()
	
	file.open("res://assets/data/" + category + "/" + json_name + "/" + json_name + difficulty + ".json", File.READ)
	var parsed_song = JSON.parse(file.get_as_text()).result
	
	var song_dict
	match chart_type:
		ChartType.FNFVR:
			song_dict = parsed_song
		_: # ChartType.SNIFF
			song_dict = parsed_song.song
	
	song_name = song_dict.song
	sections = song_dict.notes
	bpm = song_dict.bpm
	needs_vocals = song_dict.needsVoices
	speed = song_dict.speed
	
	song = load("res://assets/music/" + category + "/" + json_name + "/Inst." + extension)
	
	if needs_vocals:
		vocals = load("res://assets/music/" + category + "/" + json_name + "/Voices." + extension)
