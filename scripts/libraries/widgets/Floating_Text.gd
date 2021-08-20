extends Spatial

export(String, MULTILINE) var text = "Test" setget update_text
export(Font) var font setget update_font
export(Color) var text_color = Color.white setget update_text_color

export(bool) var transparent = false setget update_transparency
export(Color) var bg_color = Color.black setget update_bg_color

onready var viewport = $Viewport
onready var bg = $Viewport/ColorRect
onready var label = $Viewport/Label
onready var sprite = $Sprite3D

func _ready():
	update()

func update_text(string):
	text = string
	
	if Engine.editor_hint:
		editor_update()
	else:
		update()

func update_font(fnt):
	font = fnt
	update()

func update_text_color(col):
	text_color = col
	
	if Engine.editor_hint:
		editor_update()
	else:
		update()

func update_transparency(is_transp):
	transparent = is_transp
	
	if Engine.editor_hint:
		editor_update()
	else:
		update()

func update_bg_color(col):
	bg_color = col
	
	if Engine.editor_hint:
		editor_update()
	else:
		update()

func update():
#	if label:
	viewport.transparent_bg = transparent
	bg.visible = !transparent
	if !transparent:
		bg.color = bg_color
	
	if font:
		label.add_font_override("font", font)
	
	label.text = text
	label.add_color_override("font_color", text_color)
	label.rect_size = Vector2()
	label.force_update_transform()
	
	bg.rect_size = label.rect_size
	
	viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
	viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ALWAYS
	yield(get_tree(), "idle_frame")
	
	viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
	viewport.render_target_clear_mode = Viewport.CLEAR_MODE_NEVER
	
	sprite.texture = viewport.get_texture()

func editor_update():
	$Viewport.transparent_bg = transparent
	$Viewport/ColorRect.visible = !transparent
	if !transparent:
		$Viewport/ColorRect.color = bg_color
	
	if font:
		$Viewport/Label.add_font_override("font", font)
	
	$Viewport/Label.text = text
	$Viewport/Label.add_color_override("font_color", text_color)
	$Viewport/Label.rect_size = Vector2()
	$Viewport/Label.force_update_transform()
	
	$Viewport/ColorRect.rect_size = $Viewport/Label.rect_size
	
	$Viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
	$Viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ALWAYS
	yield(get_tree(), "idle_frame")
	
	$Viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
	$Viewport.render_target_clear_mode = Viewport.CLEAR_MODE_NEVER
	
	$Sprite3D.texture = $Viewport.get_texture()
