@icon("res://assets/Icon/ActorIcon.png")
extends CharacterBody2D
class_name Actor

const DAMAGENUMBER = preload("res://src/Effect/DamageNumber.tscn")
const FLOOR_NORMAL: = Vector2.UP

@export var editor_hidden = true

@export var speed: = Vector2(150, 350)
var gravity: = 300
var acceleration = 50
var ground_cof = 0.2
var air_cof = 0.05

var dead = false
var is_in_water = false
var home := Vector2(0, 0)
var rng = RandomNumberGenerator.new()
@onready var world = get_tree().get_root().get_node("World")

#do not _ready() as it will be shadowed

#func on_editor_select():
	#modulate = Color(2,2,2)
#
#func on_editor_deselect():
	#modulate = Color(1,1,1)
