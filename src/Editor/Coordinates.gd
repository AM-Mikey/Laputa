extends MarginContainer

#var x = 0
#var y = 0


var mouse_pos

onready var w = get_tree().get_root().get_node("World")
onready var editor = get_parent().get_parent()

func _process(delta):
	var mouse_pos = w.get_global_mouse_position()
	$Label.text = String(editor.get_cell(mouse_pos))
