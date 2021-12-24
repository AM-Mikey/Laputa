extends Area2D

class_name Trigger, "res://assets/Icon/TriggerIcon.png"

var active_pc = null
var trigger_type = ""

func _ready():
	add_to_group("Triggers")

func get_overlap() -> bool:
	var _triggers_touching = 0
	for t in get_tree().get_nodes_in_group("Triggers"):
		if t.active_pc != null and t.trigger_type == trigger_type:
			_triggers_touching += 1
	
	if _triggers_touching > 1: 
		return true
	else: 
		return false
