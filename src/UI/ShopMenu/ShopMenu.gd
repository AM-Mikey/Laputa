extends MarginContainer

const CURSOR = preload("res://src/UI/ShopMenu/Cursor.tscn")

export(NodePath) var items

func _ready():
	focus()

func focus():
	get_node(items).get_child(0).grab_focus()
#	cursor_select(0)
#
#func cursor_select(index):
#	get_node(items).get_child(index).add_child(CURSOR.instance())
