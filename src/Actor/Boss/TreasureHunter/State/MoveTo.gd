extends State

@export var delta_error: float = 4.0
var target_position: Vector2 = Vector2.ZERO
var reach_destination: bool = false
var move_speed: float = 60.0


func state_start(_prev_state: StringName):
	reach_destination = false
	main.ap.play("fly")

func state_physics_process(_delta: float):
	var distance_to_pos = main.global_position.distance_to(target_position)
	if distance_to_pos < delta_error:
		if !reach_destination:
			main.end_move_to.emit()
		reach_destination = true
		return

	var direction = main.global_position.direction_to(target_position)
	main.velocity = direction * move_speed
	main.move_and_slide()
