extends Level

const SCARY_MATS = [
	preload("res://assets/models/stages/week_5/scary_mats/walls.material"),
	preload("res://assets/models/stages/week_5/scary_mats/walkway.material"),
	preload("res://assets/models/stages/week_5/scary_mats/sky.material"),
	preload("res://assets/models/stages/week_5/scary_mats/ceiling.material"),
	preload("res://assets/models/stages/week_5/scary_mats/stairs.material"),
	preload("res://assets/models/stages/week_5/scary_mats/snow.material"),
	preload("res://assets/models/stages/week_5/scary_mats/snow_cell.material")
]
const LIGHTS_TURN_ON = preload("res://assets/sounds/Lights_Turn_On.ogg")

onready var parents = $Wk5
onready var santa = $Santa
onready var cops = $Cops
onready var tree_normal = $TreeNormal
onready var tree_monster = $TreeMonster
onready var monster = $Monster
onready var stage = $Week_5_Stage
onready var scary_noise = $Scary_Noise
onready var environment_anim = $WorldEnvironment/AnimationPlayer

func on_ready():
	opponent = $Wk5
	metronome = $ChrGirlfriend
	
	opponent_icons_idx = 30
	
	Player.christmas_outfit = true
	Player.switch_materials()
	
	.on_ready()

func set_songs():
	if !song_json_names.empty():
		return
	
	song_json_names = ["cocoa", "eggnog", "winter-horrorland"]

func do_level_prep():
	match songs[0].song_name:
		"Winter-Horrorland":
			if is_freeplay:
				change_to_scary_level()
			
			opponent = monster
			opponent_icons_idx = 35
			
			generate_bpm_changes()
		_:
			var time_in_sixteenths = 0
			
			santa.anim_player.playback_speed = 2.08 / Conductor.get_seconds_per_beat()
			cops.anim_player.playback_speed = santa.anim_player.playback_speed
			
			for section in songs[0].sections:
				onetime_events.append([
					time_in_sixteenths / 4.0,
					Conductor.Notes.QUARTER,
					funcref(parents, "set"),
					["moms_turn", section.has("altAnim")]
				])
				
				time_in_sixteenths += 16

func do_pre_level_event():
	if songs[0].song_name == "Winter-Horrorland":
		environment_anim.play("Lights_Out")
		scary_noise.play()
		yield(get_tree().create_timer(1.75), "timeout")
		
		change_to_scary_level()
		opponent_icon.frame = 37
		environment_anim.play("Red_Flash")
		
		show()
		scary_noise.stop()
		scary_noise.stream = LIGHTS_TURN_ON
		scary_noise.play()
		
		yield(get_tree().create_timer(3.3), "timeout")

func do_level_cleanup():
	Player.christmas_outfit = false
	Player.switch_materials()
	
	.do_level_cleanup()

func change_to_scary_level():
	var stage_parts = stage.get_children()
	
	parents.hide()
	santa.hide()
	cops.hide()
	tree_normal.hide()
	metronome.hide()
	
	monster.show()
	tree_monster.show()
	
	for i in len(stage_parts):
		stage_parts[i].material_override = SCARY_MATS[i]
