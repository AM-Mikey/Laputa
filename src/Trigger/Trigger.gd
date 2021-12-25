extends Area2D
class_name Trigger, "res://assets/Icon/TriggerIcon.png"

var sfx_door = load("res://assets/SFX/placeholder/snd_door.ogg")
var sfx_locked = load("res://assets/SFX/placeholder/snd_gun_click.ogg")

const TRIGGER_VISUAL = preload("res://src/Utility/TriggerVisual.tscn")

export var color = Color(1, 0, 0)

var active_pc = null
var trigger_type = ""
var limited = false
var spent = false

func _ready():
	add_to_group("Triggers")
	add_child(TRIGGER_VISUAL.instance())

func get_overlap() -> bool:
	var _triggers_touching = 0
	for t in get_tree().get_nodes_in_group("Triggers"):
		if t.active_pc != null and t.trigger_type == trigger_type:
			_triggers_touching += 1
	
	if _triggers_touching > 1: 
		return true
	else: 
		return false
