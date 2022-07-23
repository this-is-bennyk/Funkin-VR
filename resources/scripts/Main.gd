extends "res://scripts/general/StateManager.gd"

const DISCLAIMER = preload("res://packages/fnfvr/resources/scenes/menus/Disclaimer.tscn")

onready var player = $Player
onready var loader = $LoaderVR

func _ready():
	Physics2DServer.set_active(false)
	PhysicsServer.set_active(false)
	
	if player.origin.auto_initialise:
		return
	
	# Otherwise we're going into debug mode
	_on_init_success()

func _on_init_success():
	TransitionSystem.reset()
	
	if player.origin.auto_initialise:
		switch_state(DISCLAIMER)
	else:
		switch_state("res://packages/fnfvr/testing/LevelTester.tscn")

func switch_state(scene, scene_variables: Dictionary = {}):
	clear_current_state()
	
	var new_state
	
	if scene is PackedScene:
		new_state = scene.instance()
	else: # Assumed to be a String
		loader.load_objects([scene])
		var scene_dict = yield(loader, "loaded")
		new_state = scene_dict[scene].instance()
	
	for variable in scene_variables:
		new_state.set(variable, scene_variables[variable])
	
	add_child(new_state)

func clear_current_state():
	for child in get_children():
		if child == player || child == loader:
			continue
		remove_child(child)
		child.queue_free()
