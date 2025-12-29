@icon("res://assets/Icon/PropIcon.png")
extends CharacterBody2D
class_name Prop

var sfx_ammo_refill = load("res://assets/SFX/placeholder/snd_get_missile.ogg")
var sfx_deny = load("res://assets/SFX/placeholder/snd_quote_bonkhead.ogg")
var sfx_chest = load("res://assets/SFX/placeholder/snd_chest_open.ogg")


var active_pc = null
var prop_type = ""
var spent = false
var rng = RandomNumberGenerator.new()
var gravity = 300.0

var is_in_water = false: set = set_is_in_water

@export var base_gravity: float = 300.0
@export var water_gravity: float = 150.0
@export var editor_hidden = false

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	#safe_margin = 0.001
	setup()

func setup(): #for children
	pass

func _input(event):
	if event.is_action_pressed("inspect") and not spent and active_pc != null:
		if not active_pc.disabled and active_pc.can_input:
			activate()

func activate(): #for children
	pass

func set_is_in_water(val):
	gravity = base_gravity if !val else water_gravity
	is_in_water = val

func _on_body_entered(body):
	active_pc = body.get_parent()
func _on_body_exited(_body):
	active_pc = null
