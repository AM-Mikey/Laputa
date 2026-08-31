extends Bullet

var texture: CompressedTexture2D
var texture_index: int
var collision_shape: RectangleShape2D

var minimum_speed: float = 6
var bounciness = 1 #.6
var start_velocity
var touched_floor = false

@onready var pc = f.pc()
@onready var pc_on_floor = pc.is_on_floor()
@onready var pc_held_down = Input.is_action_pressed("look_down") and inp.can_act

func setup():
	$FizzleTimer.start(f_time)
	break_method = "cut"
	velocity = get_initial_velocity()
	start_velocity = abs(velocity.x) + abs(velocity.y) / 2.0 #used to calculate animation slowdown


func _on_physics_process(delta):
	velocity.y += gravity * delta

	if velocity.x > 0:
		$AnimationPlayer.play("FlipLeft")
	else:
		$AnimationPlayer.play("FlipRight")

	var collision = move_and_collide(velocity * delta)
	if collision:
		if abs(velocity.y) > minimum_speed:
			velocity *= bounciness
			velocity = velocity.bounce(collision.get_normal())
			am.play("gun_star_bounce", self)
		else:
			velocity = Vector2.ZERO

	if wind_areas_inside.size() != 0: #Inside Wind
		if velocity.y < 0:
			velocity.y *= 0.9
	var avr_velocity = abs(velocity.x) + abs(velocity.y) / 2.0 #used to calculate animation slowdown

	$AnimationPlayer.speed_scale = avr_velocity / start_velocity
	if $AnimationPlayer.speed_scale < .1:
		$AnimationPlayer.stop()


func get_initial_velocity() -> Vector2:
	var out = velocity
	out.x = speed * direction.x
	out.y = speed * direction.y
	if pc_on_floor and pc_held_down:  #look down on ground
		out.y -= 40
	elif pc_held_down: #look down midair
		pass
	else:
		out.y -= 80 #give us some ups to start with
	return out



### SIGNALS ###

func _on_CollisionDetector_body_entered(body): #shadows
	if not body is TileMapLayer:
		#armor
		if body.get_collision_layer_value(6):
			if armor_check(body):
				do_fizzle("armor")
		#enemys
		elif body.get_collision_layer_value(2):
			if not touched_floor:
				body.hit(damage, get_blood_dir(body))
			else:
				body.hit(int(damage / 2.0), get_blood_dir(body))
			queue_free()
		#breakable
		elif body.get_collision_layer_value(9):
			on_break(break_method)

func _on_FizzleTimer_timeout():
	do_fizzle("range")
