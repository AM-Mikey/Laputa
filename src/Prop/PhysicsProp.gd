@icon("res://assets/Icon/PhysicsPropIcon.png")
extends RigidBody2D
class_name PhysicsProp

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

func set_is_in_water(val):
	gravity_scale = base_gravity_scale if !val else water_gravity_scale
	is_in_water = val
