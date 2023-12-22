extends Actor

var falling = false
var camera_forgiveness_distance = 64
@export var wait_time = 0.8
@export var respawn_time = 4.0

@onready var starting_position = position


func _physics_process(_delta):
	var camera_limiters = get_tree().get_nodes_in_group("CameraLimiters")
	var bottom
	for c in camera_limiters:
		bottom = c.get_node("Bottom").global_position.y
	#if global_position.y > bottom + camera_forgiveness_distance:
		#print("falling channel left camera limits, freeing")
		#free()

	if falling:
		velocity = calculate_movevelocity(velocity)
		set_velocity(velocity)
		set_up_direction(FLOOR_NORMAL)
		move_and_slide()
		velocity = velocity


func calculate_movevelocity(linearvelocity: Vector2) -> Vector2:
	var out: = linearvelocity
	out.y += gravity * get_physics_process_delta_time()
	return out


func _on_PlayerDetector_body_entered(body):
	$Timer.start(wait_time)
	$AnimationPlayer.play("Shake")


func _on_Timer_timeout():
	if not falling:
		$FallSound.play()
		falling = true
		$Timer.start(respawn_time)
	else:
		velocity = Vector2.ZERO
		falling = false
		position = starting_position
		$AnimationPlayer.play("Flash")

