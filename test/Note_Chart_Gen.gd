extends Node

var songs = []
var song_json_names = ["bopeebo"]

var note_list = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	for json_name in song_json_names:
		songs.append(SongChart.new(json_name, "-easy"))
	
	# TODO: Right now we're assuming that there will be no notes in the step zones
	# when a song is finished. This should be true in all cases, but you never know.
	set_process(false)
	
#		opponent.stop()
	# metronome.stop()
	
	var cur_chart: SongChart = songs.pop_front()
	note_list = {}
	
	for section in cur_chart.sections:
		for note in section["sectionNotes"]:
			var strum_time = note[0] / 1000.0
			var spawn_time = strum_time - Conductor.get_seconds_per_beat() * 2
			
			if note_list.has(spawn_time):
				if int(note[1]) > 3:
					note_list[spawn_time].append([int(note[1]) - 4, strum_time, !section["mustHitSection"], note[2] / 1000.0])
				else:
					note_list[spawn_time].append([int(note[1]), strum_time, section["mustHitSection"], note[2] / 1000.0])
			
			else:
				if int(note[1]) > 3:
					note_list[spawn_time] = [[int(note[1]) - 4, strum_time, !section["mustHitSection"], note[2] / 1000.0]]
				else:
					note_list[spawn_time] = [[int(note[1]), strum_time, section["mustHitSection"], note[2] / 1000.0]]
	
	print(note_list)
