extends Area2D
class_name Trigger, "res://assets/Icon/TriggerIcon.png"

const TRIGGER_VISUAL = preload("res://src/Utility/TriggerVisual.tscn")
const TRIGGER_CONTROLLER = preload("res://src/Editor/TriggerController.tscn")

export var editor_hidden = false
export var color = Color(1, 0, 0)

var active_pc = null
var active_bodies = []
var trigger_type = ""
var spent = false

onready var w = get_tree().get_root().get_node("World")
onready var visual = TRIGGER_VISUAL.instance()


func _ready():
	add_to_group("Triggers")
	add_child(visual)
	if w.get_node("EditorLayer").has_node("Editor"):
		var controller = TRIGGER_CONTROLLER.instance()
		var col = $CollisionShape2D
		controller.rect_position = col.position - col.shape.extents
		controller.rect_size = col.shape.extents * 2
		add_child(controller)

func get_overlap(body) -> bool:
	var body_in_triggers = 0
	for t in get_tree().get_nodes_in_group("Triggers"):
		if t.active_bodies.has(body) and t.trigger_type == trigger_type:
			body_in_triggers += 1
	
	if body_in_triggers > 1: 
		return true
	else: 
		return false

#
#func get_overlap() -> bool:
#	var _triggers_touching = 0
#	for t in get_tree().get_nodes_in_group("Triggers"):
#		if t.active_pc != null and t.trigger_type == trigger_type:
#			_triggers_touching += 1
#
#	if _triggers_touching > 1: 
#		return true
#	else: 
#		return false

func expend_trigger():
	spent = true
	visible = false


### EDITOR

func _input_event(viewport, event, shape_idx): #selecting in editor
	var editor = w.get_node("EditorLayer/Editor")
	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT and event.is_pressed():
		editor.inspector.on_selected(self, "trigger")
		#print("clicked on a trigger")


func on_editor_select():
	visual.self_modulate = Color(2,2,2)

func on_editor_deselect():
	visual.self_modulate = Color(1,1,1)

