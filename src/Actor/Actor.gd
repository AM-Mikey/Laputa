extends KinematicBody2D
class_name Actor, "res://assets/Icon/ActorIcon.png"

const DAMAGENUMBER = preload("res://src/Effect/DamageNumber.tscn")
const FLOOR_NORMAL: = Vector2.UP

export var editor_hidden = false

export var speed: = Vector2(150, 350)
export var gravity: = 300
var velocity: = Vector2.ZERO
var acceleration = 50
export var ground_cof = 0.2
export var air_cof = 0.05

var dead = false
var is_in_water = false
var home := Vector2(0, 0)
var rng = RandomNumberGenerator.new()
onready var world = get_tree().get_root().get_node("World")

func _ready():
	add_to_group("Actors")
	add_to_group("Entities")
	home = global_position

func _input_event(viewport, event, shape_idx): #selecting in editor
	var editor = world.get_node("EditorLayer/Editor")
	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT and event.is_pressed():
		editor.inspector.on_selected(self, editor.get_entity_type(self))
		#print("clicked on an actor")


func on_editor_select():
	modulate = Color(2,2,2)

func on_editor_deselect():
	modulate = Color(1,1,1)
