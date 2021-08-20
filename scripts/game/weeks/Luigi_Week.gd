extends Level

var luigi_peace_beats = [15, 30, 39, 55, 71, 87, 114, 122, 151, 167, 193, 207, 224, 247, 263, 271]

func on_ready():
	opponent = $Luigi
	metronome = $Girlfriend
	
	opponent_icons_idx = 65
	
	.on_ready()

func set_songs():
	if !song_json_names.empty():
		return
	
	song_json_names = ["heavenfunk"]
	category = "weegee"
	chart_type = SongChart.ChartType.FNFVR

func do_level_prep():
	var peace_func = funcref($Luigi, "play_anim")
	var peace_args = ["Peace"]
	
	onetime_events = []
	
	for peace_beat in luigi_peace_beats:
		onetime_events.append(
			[
				peace_beat,
				Conductor.Notes.QUARTER,
				peace_func,
				peace_args
			]
		)
