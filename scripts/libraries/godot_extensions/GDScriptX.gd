class_name GDScriptX

static func xor(a, b):
	if (a && !b) || (b && !a):
		return true
	return false
