@icon("res://assets/Icon/TriggerIcon.png")
extends Area2D
class_name Trigger

@export var editor_hidden = false
@export var color = Color(1, 0, 0)

var active_pc = null
var active_bodies = []
var trigger_type = ""
var spent = false

@onready var w = get_tree().get_root().get_node("World")

func get_overlap(body) -> bool:
	var body_in_triggers = 0
	for t in get_tree().get_nodes_in_group("Triggers"):
		if t.active_bodies.has(body) and t.trigger_type == trigger_type:
			body_in_triggers += 1

	if body_in_triggers > 1:
		return true
	else:
		return false


func expend_trigger():
	spent = true
	visible = false
