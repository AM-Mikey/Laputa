extends Area2D

@export var owner_id: String
@export var index := 0

var active_count = 0

@onready var w = get_tree().get_root().get_node("World")

func _ready():
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
		1: modulate = Color.RED
		2: modulate = Color.DARK_RED
		3: modulate = Color.DARK_MAGENTA
		4: modulate = Color.DARK_BLUE
		_: modulate = Color.BLACK
