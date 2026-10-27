extends CharacterBody2D

var free_speed := 8.0
var bounciness := 0.6
var air_cof := 0.10
var free_time := 2.0

var direction : Vector2
var gravity := 300.0
var min_speed := 60.0
var max_speed := 120.0
var spread_degrees := 40.0
var rng = RandomNumberGenerator.new()


func _ready():
	velocity = get_initial_velocity()
	#initial_velocity = velocity
	$FreeTimer.start(free_time)

func _physics_process(delta):
	velocity.x = lerp(velocity.x, 0.0, air_cof)
	velocity.y += gravity * delta
	if velocity.y < 0.0: #going up
		velocity.y = lerp(velocity.y, 0.0, air_cof)


	var collision = move_and_collide(velocity * delta)
	if collision:
		if velocity.length() > free_speed:
			velocity *= bounciness
			velocity = velocity.bounce(collision.get_normal())
			#am.play("bullet_birdshot_bounce", self)
		else:
			velocity = Vector2.ZERO
			#queue_free()


### GETTERS ###

func get_initial_velocity() -> Vector2:
	var out = velocity

	direction = get_direction_from_spread_degrees()
	rng.randomize()
	var speed := randf_range(min_speed, max_speed)
	out.x = speed * direction.x
	out.y = speed * direction.y
	#out += f.pc().velocity #this fixes bullets traveling less because we're moving forward
	#out.y -= 50 #give us some ups to start with
	return out

func get_direction_from_spread_degrees() -> Vector2:
	var out = direction
	rng.randomize()
	var half_spread = spread_degrees / 2.0
	var angular_distance = randf_range(half_spread * -1, half_spread)
	out = out.rotated(deg_to_rad(angular_distance))
	return out

### SIGNALS ###

func _on_FreeTimer_timeout():
	$AnimationPlayer.play("Fadeout")
	await $AnimationPlayer.animation_finished
	queue_free()
