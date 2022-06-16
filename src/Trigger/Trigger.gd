extends Area2D
class_name Trigger, "res://assets/Icon/TriggerIcon.png"

var sfx_door = load("res://assets/SFX/placeholder/snd_door.ogg")
var sfx_locked = load("res://assets/SFX/placeholder/snd_gun_click.ogg")

const TRIGGER_VISUAL = preload("res://src/Trigger/TriggerVisual.tscn")

export var color = Color(1, 0, 0)

var active_pc = null
var active_bodies = []
var trigger_type = ""
var spent = false

onready var w = get_tree().get_root().get_node("World")

func _ready():
	add_to_group("Triggers")
	collision_layer = 32 #trigger
	
	var visual = TRIGGER_VISUAL.instance()
	visual.name = "Visual"
	add_child(visual)

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
	$Visual.self_modulate = Color(2,2,2)

func on_editor_deselect():
	$Visual.self_modulate = Color(1,1,1)

