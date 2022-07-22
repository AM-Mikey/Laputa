extends Area2D

export var owner_id: String
export var index := 0

var active_count = 0

onready var w = get_tree().get_root().get_node("World")

func _ready():
	add_to_group("VisualUtilities")
	add_to_group("Waypoints")
	visible = w.debug_visible


func activate():
	active_count += 1
	set_color()

func deactivate():
	active_count -= 1
	set_color()

func on_editor_select():
	modulate = Color(2,2,2)

func on_editor_deselect():
	modulate = Color(1,1,1)

func set_color():
	match active_count:
		0: modulate = Color(1,1,1)
		1: modulate = Color.red
		2: modulate = Color.darkred
		3: modulate = Color.darkmagenta
		4: modulate = Color.darkblue
		_: modulate = Color.black
