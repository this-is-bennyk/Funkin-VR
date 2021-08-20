extends Menu3D

onready var pages = [
	$Credits_VP/Credits_GUI/Page1,
	$Credits_VP/Credits_GUI/Page2,
	$Credits_VP/Credits_GUI/Page3
]
var page_idx = 0

func _ready():
	menu_items = {
		$Prev_Credits/Area: null,
		$Next_Credits/Area: null,
		$Back/Area: null
	}
	
	Conductor.play_song(preload("res://assets/music/fnf/Credits.ogg"), 160)

func do_menu_item_action():
	.do_menu_item_action()
	
	match cur_menu_item.name:
		"Prev_Credits":
			change_page(-1)
		"Next_Credits":
			change_page(1)
		"Back":
			return_to_main_menu()

func change_page(increment):
	page_idx = wrapi(page_idx + 1, 0, len(pages))
	
	for i in len(pages):
		pages[i].visible = i == page_idx
		
		match i:
			1:
				$Credits_VP/Credits_GUI/Title.text = "Attribution"
			2:
				$Credits_VP/Credits_GUI/Title.text = "Special Thanks"
			_:
				$Credits_VP/Credits_GUI/Title.text = "Credits"
