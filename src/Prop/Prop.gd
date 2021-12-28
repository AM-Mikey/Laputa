extends Node
class_name Prop, "res://assets/Icon/PropIcon.png"

var sfx_ammo_refill = load("res://assets/SFX/placeholder/snd_get_missile.ogg")
var sfx_deny = load("res://assets/SFX/placeholder/snd_quote_bonkhead.ogg")
var sfx_chest = load("res://assets/SFX/placeholder/snd_chest_open.ogg")


var active_pc = null
var prop_type = ""
var spent = false

onready var w = get_tree().get_root().get_node("World")

func _ready():
	add_to_group("Props")

func _on_body_entered(body):
	active_pc = body
func _on_body_exited(_body):
	active_pc = null

func _input(event):
	if event.is_action_pressed("inspect") and not spent and active_pc != null: 
		if not active_pc.disabled:
			activate()

func activate():
	pass
