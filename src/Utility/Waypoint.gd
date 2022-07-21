extends Area2D

export var owner_id: String
export var index := 0

onready var w = get_tree().get_root().get_node("World")

func _ready():
	add_to_group("VisualUtilities")
	add_to_group("Waypoints")
	visible = w.debug_visible


func activate():
	modulate = Color.red

func deactivate():
	modulate = Color(1,1,1)

func on_editor_select():
	modulate = Color(2,2,2)

func on_editor_deselect():
	modulate = Color(1,1,1)
