class_name MultiModelCharacter
extends Spatial

var hold_time = 0
var sixteenths_to_hold = 4
var uninterrupted_anim = false

var animation_models = {
	"Idle": null,
	"Left": null,
	"Down": null,
	"Up": null,
	"Right": null
}

var current_anim = "Idle"

# I don't think this is necessary (checking the current section to see if
# it's a must_hit_section), but we'll see
#var player_hitting = false

func _ready():
	on_ready()

func on_ready():
	for child in get_children():
		child.visible = child == animation_models.Idle
	
	animation_models.Idle.get_node("AnimationPlayer").play("Idle")
	animation_models.Idle.get_node("AnimationPlayer").stop()
	animation_models.Idle.get_node("AnimationPlayer").seek(0, true)
	
	set_process(false)
	Conductor.connect("quarter_hit", self, "on_quarter_hit")

func start():
	idle()
	set_process(true)

func stop():
	animation_models[current_anim].get_node("AnimationPlayer").stop()
	set_process(false)

func _process(delta):
	if current_anim != "Idle":
		hold_time -= delta
	
		if hold_time <= 0:
			idle()

func on_quarter_hit(quarter):
	if hold_time == 0:
		idle()

func idle():
	animation_models[current_anim].get_node("AnimationPlayer").stop()
	
	if current_anim != "Idle":
		for child in get_children():
			child.visible = child == animation_models.Idle
		current_anim = "Idle"
	
	animation_models[current_anim].get_node("AnimationPlayer").play(current_anim)
	hold_time = 0
	uninterrupted_anim = false

func play_anim(anim_name, hold_or_sustain_time = 0, overriding_time = false, uninterrupted = false):
	animation_models[current_anim].get_node("AnimationPlayer").stop()
	current_anim = anim_name
	
	for child in get_children():
		child.visible = child == animation_models[current_anim]
	
	if !uninterrupted_anim:
		animation_models[current_anim].get_node("AnimationPlayer").stop()
		animation_models[current_anim].get_node("AnimationPlayer").play(current_anim)
		
		if overriding_time:
			hold_time = hold_or_sustain_time
		else:
			hold_time = Conductor.get_sixteenth_length() * sixteenths_to_hold + hold_or_sustain_time
		
		uninterrupted_anim = uninterrupted
