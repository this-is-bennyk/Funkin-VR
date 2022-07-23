extends "res://scripts/game/LevelManager.gd"

func on_ready():
	pause_scene = preload("res://packages/fnfvr/resources/scenes/game/PauseStateVR.tscn")
	
	story_mode_path = "res://packages/fnfvr/resources/scenes/menus/Main_Menu.tscn"
	freeplay_path = "res://packages/fnfvr/resources/scenes/menus/Main_Menu.tscn"
	
	var result = _load_level_infos()
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	
	call_deferred("advance_state_stack")

func switch_state(scene, scene_variables: Dictionary = {}):
	clear_current_state()
	
	var new_state
	
	if scene is PackedScene:
		new_state = scene.instance()
	else: # Assumed to be a String
		main.loader.load_objects([scene])
		var scene_dict = yield(main.loader, "loaded")
		new_state = scene_dict[scene].instance()
	
	for variable in scene_variables:
		new_state.set(variable, scene_variables[variable])
	
	add_child(new_state)

func _load_level_infos():
	var paths = []
	for state in state_stack:
		if state is SongData:
			paths.push_back(state.level_info_paths[difficulty])
	
	main.loader.load_objects(paths)
	level_infos = yield(main.loader, "loaded")
