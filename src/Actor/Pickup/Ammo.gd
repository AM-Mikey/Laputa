extends Actor

var value: float
var dir = Vector2.DOWN
var normal_time = 2.0
var end_time = 1.0
var state = "normal"

func _ready():
	home = global_position
	
	speed = Vector2(10, 10)
	match value:
		0.2: $AnimationPlayer.play("Small")
		0.5: $AnimationPlayer.play("Large")
		_: printerr("ERROR: Ammo given non-standard value")
	$Timer.start(normal_time)

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

func _on_Timer_timeout():
	if state == "normal":
		state = "end"
		match value:
			0.2: $AnimationPlayer.play("SmallEnd")
			0.5: $AnimationPlayer.play("LargeEnd")
			_: printerr("ERROR: Ammo given non-standard value")
		$Timer.start(end_time)
	elif state == "end":
		state = "pop"
		match value:
			0.2: $AnimationPlayer.play("SmallPop")
			0.5: $AnimationPlayer.play("LargePop")
			_: printerr("ERROR: Ammo given non-standard value")


func clear():
	queue_free()
