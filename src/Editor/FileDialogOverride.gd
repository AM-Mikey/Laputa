extends FileDialog

func _ready():
	for c in get_all_children(self, [], false):
		if c is LineEdit:
			print("got linedit")
			c.set_script(load("res://src/Editor/LineEditOverride.gd"))
	dialog_close_on_escape = false

func get_all_children(in_node, arr := [], include_self := true):
	if include_self: arr.append(in_node)
	for child in in_node.get_children(true):
		arr = get_all_children(child,arr)
	return arr
