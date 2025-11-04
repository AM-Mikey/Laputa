@icon("res://assets/Icon/PropIcon.png")
extends CharacterBody2D
class_name Prop

var sfx_ammo_refill = load("res://assets/SFX/placeholder/snd_get_missile.ogg")
var sfx_deny = load("res://assets/SFX/placeholder/snd_quote_bonkhead.ogg")
var sfx_chest = load("res://assets/SFX/placeholder/snd_chest_open.ogg")


var active_pc = null
var prop_type = ""
var spent = false
@export var editor_hidden = false

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	add_to_group("Props") #TODO: consider doing this in editor
	add_to_group("Entities")

func _on_body_entered(body):
	active_pc = body.get_parent()
func _on_body_exited(_body):
	active_pc = null

func _input(event):
	if event.is_action_pressed("inspect") and not spent and active_pc != null:
		if not active_pc.disabled and active_pc.can_input:
			activate()

func activate():
	pass

#func _input_event(viewport, event, shape_idx): #selecting in editor
	#var editor = w.get_node("EditorLayer/Editor")
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		#editor.inspector.on_selected(self, "prop")
		##print("clicked on a prop")
