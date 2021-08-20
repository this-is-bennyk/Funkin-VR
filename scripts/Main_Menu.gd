extends Spatial

# ---------- Level Selection ----------

signal level_selected
var level_paths = [
	"res://prototypes/game/weeks/Week_1.tscn",
	"res://prototypes/game/weeks/Week_2.tscn",
	"res://prototypes/game/weeks/Week_3.tscn",
	"res://prototypes/game/weeks/Week_4.tscn",
	"res://prototypes/game/weeks/Luigi_Week.tscn"
]
var selected_lvl_idx = 0
var difficulty_suffix = ""

# ---------- Menus ----------

onready var menus = {
	title_screen = $Title_Screen,
	mode_select = $Mode_Select,
	campaign = $Campaign
}
onready var cur_menu = menus.title_screen

# ---------- Sounds ----------

var menu_music = preload("res://assets/music/fnf/freakyMenu.ogg")

# ---------- Scene Stuff ----------

onready var logo_anim = $Title_Screen/Logo_Anim
onready var week_num_display = $Campaign/Week_Num_Display

onready var stage_env = $Stage_Environment

onready var readme = $Readme
onready var press_start = $Title_Screen/Press_Start

onready var gf = $Girlfriend
onready var opponents = [
	$Campaign/Dad,
	$Campaign/Spooky_Kids,
	$Campaign/Pico,
	$Campaign/Mom,
	$Campaign/Luigi
]

var logo_anim_beats = [
	11,
	12, 12.25, 12.5, 12.75,
	13, 13.25, 13.5, 13.75,
	14, 14.25, 14.5, 14.75,
	15, 15.25, 15.5, 15.75,
	16
]

var already_setup = false
var intro_anim_playing = false

# ---------- Processing ----------

func _ready():
	if already_setup:
		Player.play_transition(Player.Transition.FADE_IN)
		set_process(false)
	else:
		first_time_setup()
	
	Conductor.play_song(menu_music, 102)
	
	gf.start()
	for opponent in opponents:
		opponent.start()
	
	var lvl = yield(self, "level_selected")
	
	Conductor.stop_song()
	
	gf.stop()
	for opponent in opponents:
		opponent.stop()
	
	yield(get_tree().create_timer(0.5), "timeout")
	
	Player.play_transition(Player.Transition.FADE_OUT)
	yield(Player.screen_anim, "animation_finished")
	
	get_parent().load_scene(level_paths[selected_lvl_idx],
										{"difficulty": difficulty_suffix})

func _process(delta):
	if intro_anim_playing:
		process_intro_anim()
	else:
		if Player.left_hand_just_pressed || Player.right_hand_just_pressed:
			change_menu(menus.mode_select)
			$Title_Screen/Title_Confirm.play()
			set_process(false)

func first_time_setup():
	for child in logo_anim.get_children():
		if child.name == "Logo1":
			child.opacity = 0
		elif "Logo" in child.name:
			child.hide()
	
	stage_env.visible = false
	readme.visible = false
	press_start.visible = false
	gf.visible = false
	
	$Mode_Select/Story_Mode.connect("pressed", self, "on_button_pressed")
	
	$Campaign/Prev_Week.connect("pressed", self, "on_button_pressed")
	$Campaign/Next_Week.connect("pressed", self, "on_button_pressed")
	$Campaign/Easy.connect("pressed", self, "on_button_pressed")
	$Campaign/Normal.connect("pressed", self, "on_button_pressed")
	$Campaign/Hard.connect("pressed", self, "on_button_pressed")
	
	if OS.get_name() == "Android":
		$WorldEnvironment.queue_free()
		
		$Stage_Environment/Floor/Round_Light/OmniLight.hide()
		$Stage_Environment/Floor/Round_Light2/OmniLight.hide()
		$Stage_Environment/Floor/Round_Light3/OmniLight.hide()
		$Stage_Environment/Floor/Round_Light4/OmniLight.hide()
		$Stage_Environment/Floor/Round_Light5/OmniLight.hide()
		$Stage_Environment/DirectionalLight.hide()
		
		$Stage_Environment/GLES2_Light.show()
	
	set_process(true)
	intro_anim_playing = true
	already_setup = true

func process_intro_anim():
	if logo_anim_beats.size() != 0:
		if Conductor.is_quarter(logo_anim_beats[0]):
			var lg_anim_tween = logo_anim.get_node("Tween")
			match logo_anim_beats[0]:
				11:
					lg_anim_tween.interpolate_property(logo_anim.get_node("Logo1"), "opacity", 0, 1, Conductor.get_seconds_per_beat(), Tween.TRANS_EXPO, Tween.EASE_OUT)
				16:
					for child in logo_anim.get_children():
						if child.name == "Logo18":
							child.show()
						elif "Logo" in child.name:
							child.hide()
					
					stage_env.visible = true
					readme.visible = true
					press_start.visible = true
					gf.visible = true
					
					Player.play_transition(Player.Transition.FLASH)
				_:
					var frame = logo_anim.get_node("Logo" + str(17 - logo_anim_beats.size() + 2))
					frame.show()
					
					if logo_anim_beats[0] == 15.5:
						lg_anim_tween.interpolate_property(frame, "translation:z", 1.5, 0.002, Conductor.get_seconds_per_beat() / 4.0, Tween.TRANS_BACK, Tween.EASE_OUT)
					elif logo_anim_beats[0] == 15.75:
						lg_anim_tween.interpolate_property(frame, "translation:z", 1.5, 0.001, Conductor.get_seconds_per_beat() / 4.0, Tween.TRANS_BACK, Tween.EASE_OUT)
					else:
						lg_anim_tween.interpolate_property(frame, "translation:z", 1.5, 0, Conductor.get_seconds_per_beat() / 4.0, Tween.TRANS_BACK, Tween.EASE_OUT)
			
			logo_anim.get_node("Tween").start()
			logo_anim_beats.pop_front()
	else:
		intro_anim_playing = false

# ---------- Signal Connections ----------

func on_button_pressed(node):
	match node.name:
		"Story_Mode":
			change_menu(menus.campaign)
			
		"Prev_Week", "Next_Week":
			var increment = 1 if node.name == "Next_Week" else -1
			
			selected_lvl_idx = wrapi(selected_lvl_idx + increment, 0, len(level_paths))
			week_num_display.frame = selected_lvl_idx
			
			for i in len(opponents):
				if i == selected_lvl_idx:
					opponents[i].show()
				else:
					opponents[i].hide()
		
		"Easy", "Normal", "Hard":
			match node.name:
				"Easy":
					difficulty_suffix = "-easy"
				"Hard":
					difficulty_suffix = "-hard"
				_:
					difficulty_suffix = ""
			
			emit_signal("level_selected")

# ---------- Helper Functions ----------

func change_menu(menu):
	cur_menu = menu
	
	for key in menus:
		if menus[key] == cur_menu:
			menus[key].show()
		else:
			menus[key].hide()
