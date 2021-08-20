class_name AsyncState
extends Object

# This is the only way that I am aware of where you can create
# a state that is both asynchronous to the game state and interruptable.

var yielding_state: GDScriptFunctionState
var canceling = false

func run(args: Dictionary = {}):
	yielding_state = do_yielding_event(args)

# ASSUMPTION: There is at least 1 yield statement in here with this structure:
# var result = yield(...)
#
# if canceling:
# 	Cancel the event and return to cancel() to free self
#
# Do a thing (implicit else)
func do_yielding_event(args: Dictionary = {}):
	pass

func cancel():
	canceling = true
