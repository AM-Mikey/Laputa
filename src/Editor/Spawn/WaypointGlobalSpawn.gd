extends Area2D

const WAYPOINT_GLOBAL = preload("res://src/Editor/VisualUtility/WaypointGlobal.tscn")

#@export var properties = {} #TODO: save and export hese
@export var tag_name: String
@export var index: int = 0
@export var lock_x: bool = false
@export var lock_y: bool = false

var prev_global_position
signal value_changed(what, old_val, val)

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	if w.el.get_child_count() == 0: #not in editor
		visible = false
		input_pickable = false
#name
	var name_index = 0
	for wpgs in get_tree().get_nodes_in_group("WaypointGlobalSpawns"):
		if wpgs == self: break
		else: name_index +=1
		if name_index == 0: name = "WaypointGlobalSpawn"
		else: name = str("WaypointGlobalSpawn", name_index)

func _process(_delta):
	if w.el.get_child_count() > 0:
		if prev_global_position != global_position:
			value_changed.emit(self, prev_global_position, global_position)
		prev_global_position = global_position


func spawn():
	var saved_pos = global_position
	var waypoint_global = WAYPOINT_GLOBAL.instantiate()
	waypoint_global.global_position = saved_pos
	if "id" in get_parent():
		waypoint_global.owner_id = get_parent().id
	else:
		waypoint_global.owner_id = get_parent().properties["id"][0]
	waypoint_global.index = index
	waypoint_global.tag_name = tag_name
	waypoint_global.uses_spawn = true
	w.current_level.get_node("Waypoints").add_child(waypoint_global)


### SIGNALS

func on_editor_select(): #when
	modulate = Color.RED

func on_editor_deselect():
	modulate = Color(0.0, 0.502, 1.0)


func _input_event(_viewport, event, _shape_idx): #selecting in editor
	var inspector = w.get_node("EditorLayer/Editor").inspector
	if event.is_action_pressed("editor_rmb"):
		inspector.on_selected(self, "waypoint_global_spawn")
