extends Node

@export var fly_speed = Vector2(500, 500)

@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_parent().get_parent().get_parent()
@onready var mm = pc.get_node("MovementManager")

func state_process():
	pc.move_dir = get_move_dir()
	mm.velocity = pc.move_dir * fly_speed
	pc.set_velocity(mm.velocity)
	pc.set_up_direction(mm.FLOOR_NORMAL)
	pc.set_floor_stop_on_slope_enabled(true)
	pc.move_and_slide()
	mm.velocity = pc.velocity

func get_move_dir() -> Vector2: #bypass can_input
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("look_down") - Input.get_action_strength("look_up"))



### STATES ###

func enter():
	pc.invincible = true
	pc.get_node("CollisionShape2D").set_deferred("disabled", true)
	pc.get_node("CrouchingCollision").set_deferred("disabled", true)
	pc.get_node("CrouchDetector").monitoring = false

func exit():
	pc.is_in_water = false
	pc.invincible = false
	mm.velocity = Vector2.ZERO
	pc.get_node("CollisionShape2D").set_deferred("disabled", false)
	pc.get_node("CrouchingCollision").set_deferred("disabled", false)
	pc.get_node("ItemDetector").monitoring = true
	pc.get_node("CrouchDetector").monitoring = true
