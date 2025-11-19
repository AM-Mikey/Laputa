@icon("res://assets/Icon/ActorIcon.png")
extends CharacterBody2D
class_name Actor

const DAMAGE_NUMBER = preload("res://src/Effect/EnemyDamageNumber.tscn")
const FLOOR_NORMAL: = Vector2.UP

@export var editor_hidden = true

@export var speed: = Vector2(150, 350)
var gravity: = 300
@export var base_gravity: float = 300.0
@export var water_gravity: float = 150.0
var acceleration = 50
var ground_cof = 0.2
var air_cof = 0.05

var dead = false
var is_in_water = false: set = set_is_in_water
var home := Vector2(0, 0)
var rng = RandomNumberGenerator.new()
@onready var world = get_tree().get_root().get_node("World")

func set_is_in_water(val):
	gravity = base_gravity if !val else water_gravity
	is_in_water = val

#do not _ready() as it will be shadowed

#func on_editor_select():
	#modulate = Color(2,2,2)
#
#func on_editor_deselect():
	#modulate = Color(1,1,1)
