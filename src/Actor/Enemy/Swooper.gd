extends Enemy

var dir = Vector2.LEFT

@export var swoop_height = 4
@export var swoop_distance = 8

var is_on_screen: bool = false

func setup():
	hp = 3
	damage_on_contact = 2
	speed = Vector2(100, 100)
	acceleration = 25

	reward = 3

	if dir == Vector2.LEFT:
		$AnimationPlayer.play("FlyLeft")
		$VisibleOnScreenNotifier2D.position = Vector2(16.0, -3.0)
		$PlayerDetection.target_position.x = -(swoop_distance - 1.0) * 16.0
		$PlayerDetection.position = Vector2(-8.0, (swoop_height - 0.5) * 16.0)
	elif dir == Vector2.RIGHT:
		$AnimationPlayer.play("FlyRight")
		$VisibleOnScreenNotifier2D.position = Vector2(-22.0, -3.0)
		$PlayerDetection.target_position.x = (swoop_distance - 1.0) * 16.0
		$PlayerDetection.position = Vector2(8.0, (swoop_height - 0.5) * 16.0)
	change_state("fly")

func _draw() -> void:
	if (debug):
		if (swoop_curve):
			var points: PackedVector2Array = swoop_curve.tessellate()
			for i in range(0, points.size()):
				points[i] -= global_position
			draw_polyline(points, Color.RED, 2.0)

## STATES ##
func enter_fly(_prev_state):
	if dir == Vector2.LEFT:
		$AnimationPlayer.play("FlyLeft")
	elif dir == Vector2.RIGHT:
		$AnimationPlayer.play("FlyRight")

func do_fly(_delta):
	velocity = calc_velocity(dir, false)
	move_and_slide()

	if ($PlayerDetection.is_colliding() and is_on_screen):
		change_state("swoop")

var swoop_curve: Curve2D
var swoop_t: float
func enter_swoop(_prev_state: String):
	if dir == Vector2.LEFT:
		$AnimationPlayer.play("SwoopLeft")
	elif dir == Vector2.RIGHT:
		$AnimationPlayer.play("SwoopRight")
	swoop_t = 0.0
	swoop_curve = Curve2D.new()
	swoop_curve.add_point(global_position, Vector2.ZERO, Vector2(0, swoop_height * 16))
	swoop_curve.add_point(global_position + Vector2(dir.x * swoop_distance * 16.0, 0), Vector2(0, swoop_height * 16), Vector2.ZERO)
	queue_redraw()

func do_swoop(delta: float):
	swoop_t += speed.x * 1.2 * delta
	var curr_transform: Transform2D = swoop_curve.sample_baked_with_rotation(swoop_t)
	global_position = curr_transform.get_origin()
	#global_rotation = curr_transform.get_rotation()

	if (swoop_t > swoop_curve.get_baked_length()):
		change_state("fly")

func exit_swoop(_next_state: String):
	swoop_curve = null
	swoop_t = 0.0


func _on_VisibleOnScreenNotifier2d_screen_entered() -> void:
	is_on_screen = true

func _on_VisibleOnScreenNotifier2d_screen_exited() -> void:
	is_on_screen = false
