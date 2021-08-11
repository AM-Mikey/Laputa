extends Actor

var rng = RandomNumberGenerator.new()
var direction
export var bounciness: float = .75
export var minimum_speed: float = .5
var startvelocity

export var rng_min_speed = 50
export var rng_max_speed = 100

var value: int

var decay_time = 4.0
var pop_time = 1.0

func _ready():
	$DecayTimer.start(decay_time)
	direction = randomize_direction()
	speed = randomize_speed()
	velocity = getvelocity(speed, direction)
	startvelocity = abs(velocity.x) + abs(velocity.y)/2 #used to calculate animation slowdown

	match value:
		1:
			if velocity.x < 0: $AnimationPlayer.play("SmallLeft")
			else: $AnimationPlayer.play("SmallRight")
		5:
			if velocity.x < 0: $AnimationPlayer.play("MediumLeft")
			else: $AnimationPlayer.play("MediumRight")
		20:
			$AnimationPlayer.play("FourRight")

func _physics_process(delta):
	if abs(velocity.x) > minimum_speed and abs(velocity.y) > minimum_speed:
		var collision = move_and_collide(velocity * delta)
		if collision:
			#var normal = collision.normal
			#velocity = get_bouncevelocity(velocity, normal)
			velocity *= bounciness
			velocity = velocity.bounce(collision.normal)
			if $AnimationPlayer.is_playing():
				$Bounce2D.play()
			
	velocity.y += gravity * get_physics_process_delta_time()

	var avrvelocity = abs(velocity.x) + abs(velocity.y)/2 #used to calculate animation slowdown
	$AnimationPlayer.playback_speed = avrvelocity / startvelocity
	if $AnimationPlayer.playback_speed < .1:
		$AnimationPlayer.stop()

func randomize_direction():
	rng.randomize()
	return Vector2(sign(rng.randf_range(-1.0, 1.0)), -1)
	
func randomize_speed():
	rng.randomize()
	return Vector2(rng.randf_range(rng_min_speed, rng_max_speed),rng.randf_range(rng_min_speed, rng_max_speed))
	
func getvelocity(speed, direction) -> Vector2:
	var out: = velocity
	
	out.x = speed.x * direction.x
	out.y += gravity * get_physics_process_delta_time()
	if direction.y == -1.0:
		out.y = speed.y * direction.y

	return out


func _on_DecayTimer_timeout():
	$FlashPlayer.play("Flash")
	$PopTimer.start(pop_time)
	

func _on_PopTimer_timeout():
	print("pop timer out")
	$FlashPlayer.play("Steady")
	match $AnimationPlayer.assigned_animation:
		"SmallLeft", "SmallRight": $AnimationPlayer.play("SmallPop")
		"MediumLeft", "MediumRight": $AnimationPlayer.play("MediumPop")
	yield($AnimationPlayer, "animation_finished")
	queue_free()
