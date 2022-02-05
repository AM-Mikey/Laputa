extends Node

export var fly_speed = Vector2(500, 500)

onready var world = get_tree().get_root().get_node("World")
onready var pc = world.get_node("Juniper")
onready var mm = pc.get_node("MovementManager")

func state_process():
	pc.move_dir = get_move_dir()
	mm.velocity = pc.move_dir * fly_speed
	mm.velocity = pc.move_and_slide(mm.velocity, mm.FLOOR_NORMAL, true)

func get_move_dir():
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
		)

func enter():
	pc.get_node("CollisionShape2D").disabled = true
	pc.get_node("HurtDetector").monitoring = false
	pc.get_node("ItemDetector").monitoring = false
	
func exit():
	pc.is_in_water = false
	mm.velocity = Vector2.ZERO
	pc.get_node("CollisionShape2D").disabled = false
	pc.get_node("HurtDetector").monitoring = true
	pc.get_node("ItemDetector").monitoring = true
