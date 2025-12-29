@icon("res://assets/Icon/PhysicsPropIcon.png")
extends RigidBody2D
class_name PhysicsProp

var active_pc = null
var prop_type = ""
var spent = false
var rng = RandomNumberGenerator.new()
var base_gravity_scale := 1.0
var water_gravity_scale := 0.5

var is_in_water = false: set = set_is_in_water

@export var editor_hidden = false

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	setup()

func setup(): #for children
	pass

func _input(event):
	if event.is_action_pressed("inspect") and !spent and !active_pc == null:
		if !active_pc.disabled && active_pc.can_input:
			activate()

func activate(): #for children
	pass

func set_is_in_water(val):
	gravity_scale = base_gravity_scale if !val else water_gravity_scale
	is_in_water = val

func _on_body_entered(body):
	active_pc = body.get_parent()
func _on_body_exited(_body):
	active_pc = null
