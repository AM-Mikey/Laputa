extends Area2D

signal selected(waypoint_local, type)

@export var tag_name: String
@export var index: int = 0
@export var lock_x: bool = false
@export var lock_y: bool = false

var active_count = 0

var prev_global_position
signal value_changed(what, old_val, val)

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	if w.el.get_child_count() == 0: #not in editor
		visible = false
		input_pickable = false

#name
	var name_index = 0
	for wpl in get_parent().get_children():
		if !wpl.is_in_group("WaypointLocals"): break
		if wpl == self: break
		else: name_index +=1
		if name_index == 0: name = "WaypointLocal"
		else: name = str("WaypointLocal", name_index)

func _process(_delta):
	if w.el.get_child_count() > 0:
		if (prev_global_position != global_position):
			value_changed.emit(self, prev_global_position, global_position)
		prev_global_position = global_position

### SIGNALS

func on_editor_select():
	$Sprite2D.modulate = Color.RED

func on_editor_deselect():
	$Sprite2D.modulate = Color(0.0, 0.647, 0.125)

func on_pressed():
	emit_signal("selected", self, "waypoint_local")

func _input_event(_viewport, event, _shape_idx): #selecting in editor
	var editor = w.get_node("EditorLayer/Editor")
	if event.is_action_pressed("editor_rmb"):
		editor.inspector.on_selected(self, "waypoint_local")
