extends Button

func _ready():
	connect("pressed", self, "next_dialogue_event")

func next_dialogue_event():
	Dialogic.next_event()
