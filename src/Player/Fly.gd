extends Node

@export var fly_speed = Vector2(500, 500)

@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_parent().get_parent().get_parent()
@onready var mm = pc.get_node("MovementManager")

func state_process(_delta):
	pc.move_dir = get_move_dir()
	pc.velocity = pc.move_dir * fly_speed
	pc.move_and_slide()
	pc.velocity = pc.velocity

func get_move_dir() -> Vector2: #bypass can_input
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("look_down") - Input.get_action_strength("look_up"))



### STATES ###

func enter(_prev_state: String) -> void:
	pc.invincible = true
	var disable = [
		pc.get_node("CollisionShape2D"),
		pc.get_node("CrouchingCollision")]
	mm.disable_collision_shapes(disable)
	pc.get_node("CrouchDetector").monitoring = false
	pc.set_up_direction(mm.FLOOR_NORMAL)
	pc.set_floor_stop_on_slope_enabled(true)


func exit(_next_state: String) -> void:
	pc.is_in_water = false
	pc.invincible = false
	pc.velocity = Vector2.ZERO
	var enable = [
		pc.get_node("CollisionShape2D"),
		pc.get_node("CrouchingCollision")]
	mm.enable_collision_shapes(enable)
	pc.get_node("ItemDetector").monitoring = true
	pc.get_node("CrouchDetector").monitoring = true
