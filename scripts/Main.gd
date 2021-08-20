extends Spatial

signal loaded(scene_res)

const LOADING_BLOCK_TIME = 100 # msec

onready var second_view = $Second_View
onready var second_camera = $Second_View/Viewport/Camera

var main_menu = load("res://prototypes/menus/main_menu/Main_Menu.tscn").instance()
var loader_scene = preload("res://prototypes/menus/Loader.tscn").instance()

var interactive_loader: ResourceInteractiveLoader

func _ready():
	# TODO: Find a way to make it so that I don't have to use the 3D physics server either
	Physics2DServer.set_active(false)
	if Settings.get_setting("player", "in_game_height") == -999:
		add_child(preload("res://prototypes/menus/Height_Adjuster.tscn").instance())
	else:
		add_child(preload("res://prototypes/menus/Disclaimer.tscn").instance())
	
	if OS.get_name() == "Android":
		second_view.queue_free()
	else:
		update_second_view_size()
		get_tree().get_root().connect("size_changed", self, "update_second_view_size")

# Default is main menu
func load_scene(scene_path = null, args := {}):
	if scene_path:
		# Remove current scene
		var cur_child = get_child(get_child_count() - 1)
		if cur_child == main_menu:
			remove_child(cur_child)
		else:
			cur_child.queue_free()
		
		for child in Player.camera.get_children():
			if child.name == "Screen_Anim":
				continue
			child.hide()
		
		# Add loader scene
		add_child(loader_scene)
		
		for i in 10:
			yield(get_tree(), "idle_frame")
		
		# Start interactive load
		interactive_loader = ResourceLoader.load_interactive(scene_path)
		
		# Wait for something to happen (haha omori reference)
		var scene_res = yield(self, "loaded")
		
		# Remove the loader scene
		remove_child(loader_scene)
		
		# If the loader failed, return to the main menu
		if !scene_res:
			main_menu.request_ready()
			add_child(main_menu)
			return
		
		# Otherwise, add the new scene
		var new_child = scene_res.instance()
		
		if args.size() != 0:
			for arg in args:
				new_child.set(arg, args[arg])
		
		add_child(new_child)
	
	else:
		get_child(get_child_count() - 1).queue_free()
		
#		if main_menu.already_setup:
#			main_menu.request_ready()
		add_child(main_menu)

func _process(delta):
	if !OS.get_name() == "Android":
		second_camera.global_transform = Player.camera.global_transform
	
	if interactive_loader == null:
		return

	var t = OS.get_ticks_msec()
	# Use "time_max" to control for how long we block this thread.
	while OS.get_ticks_msec() < t + LOADING_BLOCK_TIME:
	# Poll your loader.
		var err = interactive_loader.poll()

		if err == ERR_FILE_EOF: # Finished loading.
			var resource = interactive_loader.get_resource()
			interactive_loader = null
			emit_signal("loaded", resource)
			break
		
		elif err == OK:
			pass
#			var progress = interactive_loader.get_stage() / interactive_loader.get_stage_count()
#			loader_scene.get_node("Viewport/Loading_Progress").value = progress
		
		else: # Error during loading.
			interactive_loader = null
			emit_signal("loaded", null)
			break

func update_second_view_size():
	second_view.get_node("Viewport").size = OS.window_size
