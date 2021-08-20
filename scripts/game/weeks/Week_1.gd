extends Level

func on_ready():
	opponent = $Dad
	metronome = $Girlfriend
	
	.on_ready()

func set_songs():
	if !song_json_names.empty():
		return
	
	song_json_names = ["bopeebo", "fresh", "dadbattle"]
	extensions = ["ogg", "ogg", "mp3"]
