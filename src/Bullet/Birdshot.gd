extends Bullet

var initial_velocity
var cool_speed_percent := 0.25
var free_speed := 8.0
var bounciness := 0.6
var air_cof := 0.10
var cool_time := 0.5
var free_time := 3.0
var cool := false

func _ready():
	break_method = "cut"
	velocity = get_initial_velocity()
	initial_velocity = velocity
	$FreeTimer.start(free_time)
	$CoolTimer.start(cool_time)

func _physics_process(delta):
	if disabled: return
	velocity.x = lerp(velocity.x, 0.0, air_cof)
	velocity.y += gravity * delta
	if velocity.y < 0.0: #going up
		velocity.y = lerp(velocity.y, 0.0, air_cof)

	if velocity.length() < initial_velocity.length() * cool_speed_percent:
		cool = true
		$AnimationPlayer.play("Cool")

	var collision = move_and_collide(velocity * delta)
	if collision:
		cool = true
		$AnimationPlayer.play("Cool")
		if velocity.length() > free_speed:
			velocity *= bounciness
			velocity = velocity.bounce(collision.get_normal())
			am.play("bullet_birdshot_bounce", self)
		else:
			velocity = Vector2.ZERO
			queue_free()


### GETTERS ###

func get_initial_velocity() -> Vector2:
	var out = velocity
	direction = get_direction_from_spread_degrees()
	out.x = speed * direction.x
	out.y = speed * direction.y
	out += f.pc().velocity #this fixes bullets traveling less because we're moving forward
	#if pc_on_floor and pc_held_down:  #look down on ground
		#out.y -= 50
	#elif pc_held_down: #look down midair
		#pass
	#else:
	out.y -= 50 #give us some ups to start with
	return out

func get_direction_from_spread_degrees() -> Vector2:
	var out = direction
	rng.randomize()
	var half_spread = spread_degrees / 2.0
	var angular_distance = randf_range(half_spread * -1, half_spread)
	out = out.rotated(deg_to_rad(angular_distance))
	return out

### SIGNALS ###

func _on_CollisionDetector_body_entered(body):
	if disabled: return
	if cool: return
	if !body is TileMapLayer:
		if body.get_collision_layer_value(9): #breakable
			on_break(break_method)
		elif body.get_collision_layer_value(6): #armor
			do_fizzle("armor")


func _on_CollisionDetector_area_entered(area):
	if disabled: return
	if cool: return

	if area.get_collision_layer_value(18): #enemyhurt
		area.get_parent().hit(damage, get_blood_dir(area.get_parent()))
		queue_free()
	elif area.get_collision_layer_value(9): #breakable
		area.get_parent().on_break(break_method)
		#on_break(break_method) produced two fizzle particles so instead do:
		queue_free()
	elif area.get_collision_layer_value(6): #armor
		print("armor")
		do_fizzle("armor")


func _on_FreeTimer_timeout() -> void:
	queue_free()

func _on_CoolTimer_timeout() -> void:
	cool = true
	$AnimationPlayer.play("Cool")
