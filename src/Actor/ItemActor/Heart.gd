extends Actor

var value: int

var dir = Vector2.DOWN

func _ready():
	speed = Vector2(10, 10)
	
	if value == 2:
		$AnimationPlayer.play("Small")
	elif value == 4:
		$AnimationPlayer.play("Medium")
	elif value == 8:
		$AnimationPlayer.play("Large")
	else:
		print("ERROR: Heart given non-standard value")

func _physics_process(delta):
	var _velocity = get_velocity(speed, dir)
	move_and_slide(_velocity)



func get_velocity(speed, direction) -> Vector2:
	var out: = _velocity
	
	out.x = speed.x * direction.x
	out.y += gravity * get_physics_process_delta_time()
	if direction.y == -1.0:
		out.y = speed.y * direction.y

	return out

func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()
