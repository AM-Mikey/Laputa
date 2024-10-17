extends Actor

var value: float

var dir = Vector2.DOWN

func _ready():
	add_to_group("Actors")
	add_to_group("Entities")
	home = global_position
	
	speed = Vector2(10, 10)
	match value:
		0.2: $AnimationPlayer.play("Small")
		0.5: $AnimationPlayer.play("Large")

func _physics_process(_delta):
	velocity = calc_velocity(speed, dir)
	move_and_slide()

func calc_velocity(speed, direction) -> Vector2:
	var out: = velocity
	out.x = speed.x * direction.x
	out.y += gravity * get_physics_process_delta_time()
	if direction.y == -1.0:
		out.y = speed.y * direction.y
	return out

func _on_AnimationPlayer_animation_finished(_anim_name):
	queue_free()
