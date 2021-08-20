class_name Menu3D
extends Spatial

var menu_items = {}
var cur_menu_item = null

func _process(delta):
	var left_collider = Player.left_raycast.get_collider()
	var right_collider = Player.right_raycast.get_collider()
	
	if GDScriptX.xor(left_collider in menu_items.keys(), right_collider in menu_items.keys()):
		var menu_selection = left_collider.get_parent() if left_collider in menu_items.keys() else right_collider.get_parent()
		
		if cur_menu_item != menu_selection:
			if cur_menu_item:
				cur_menu_item.get_node("AnimationPlayer").stop()
				cur_menu_item.get_node("AnimationPlayer").play("Normal")
			cur_menu_item = menu_selection
			cur_menu_item.get_node("AnimationPlayer").stop()
			cur_menu_item.get_node("AnimationPlayer").play("Hover")
	else:
		if cur_menu_item:
			cur_menu_item.get_node("AnimationPlayer").stop()
			cur_menu_item.get_node("AnimationPlayer").play("Normal")
			cur_menu_item = null
		return
	
	var menu_area = cur_menu_item.get_node("Area")
	
	# Should already be mutually exclusive
	if Player.left_hand_trigger_just_pressed  && Player.left_raycast.get_collider()  == menu_area || \
	   Player.right_hand_trigger_just_pressed && Player.right_raycast.get_collider() == menu_area:
		do_menu_item_action()

func do_menu_item_action():
	cur_menu_item.get_node("AnimationPlayer").stop()
	cur_menu_item.get_node("AnimationPlayer").play("Selected")

# STANDARD: Buttons are Areas with only one CollisionShape with its default name.
# item: A key from the menu_items array.
func set_item_interactable(item, interactable):
	item.get_node("CollisionShape").disabled = interactable
#	item.monitoring = interactable
#	item.monitorable = interactable

func return_to_main_menu():
	set_process(false)
	
	Player.play_transition(Player.Transition.FADE_OUT)
	yield(Player.screen_anim, "animation_finished")
	
	get_parent().load_scene("res://prototypes/menus/main_menu/Main_Menu.tscn")
