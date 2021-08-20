extends Spatial

#signal scene_loaded(scene_res)
#
#const FALLBACK = preload("res://prototypes/Main_Menu.tscn")
#
#enum Scenes {
#	MAIN_MENU = -1,
#	TUTORIAL = 0,
#	WEEK_1,
#	WEEK_2
#}
#
#onready var loading_anim = $Loading_Icon/AnimationPlayer
#onready var loading_text = $Viewport/Loading_Text
#onready var loading_progress = $Viewport/Loading_Progress
#
#var root
#var current_scene
#var load_path = ""
#
#func _ready():
#	loading_progress.value = 0
#	loading_text.text = ""
#
#	root = get_tree().get_root()
#	current_scene = root.get_child(root.get_child_count() - 1)
#
#	hide()
#	set_process(false)
#
#func load_scene(scene_to_load):
#	load_path = match_scene(scene_to_load)
#
#	# Get rid of the current scene
#	root.remove_child(current_scene)
#	current_scene.queue_free()
#
#	# Show the loading anim
#	if OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES3:
#		Player.screen_wipe.hide()
#	else:
#		Player.screen_wipe_gles2.hide()
#
#	show()
#	loading_anim.play("Spin")
#	loading_progress.value = 0
#
#	# Get the scene resource
#	ResourceQueue.queue_resource(load_path)
#	set_process(true)
#	var scene_res = yield(self, "scene_loaded")
#
#	# Hide the loading anim
#	loading_anim.stop()
#	hide()
#
#	if OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES3:
#		Player.screen_wipe.show()
#	else:
#		Player.screen_wipe_gles2.show()
#
#	# Instance the new scene
#	if scene_res:
#		current_scene = scene_res.instance()
#	else:
#		current_scene = FALLBACK.instance()
#
#	root.add_child(current_scene)
#
#func _process(delta):
#	var progress = ResourceQueue.get_progress(load_path)
#
#	if progress == -1 || progress == 1:
#		set_process(false)
#		emit_signal("scene_loaded", ResourceQueue.get_resource(load_path))
#	else:
#		loading_progress.value = ResourceQueue.get_progress(load_path)
#
#func match_scene(scene_to_load):
#	match scene_to_load:
#		Scenes.MAIN_MENU:
#			loading_text.text = "Loading..."
#			return "res://prototypes/Main_Menu.tscn"
#
#		Scenes.WEEK_1:
#			loading_text.text = "Loading Week 1..."
#			return "res://prototypes/game/weeks/Week_1.tscn"
#
#		Scenes.WEEK_2:
#			loading_text.text = "Loading Week 2..."
#			return "res://prototypes/game/weeks/Week_2.tscn"
