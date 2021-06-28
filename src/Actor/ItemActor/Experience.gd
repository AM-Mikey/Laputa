extends Actor

var rng = RandomNumberGenerator.new()
var direction
export var bounciness: float = .75
export var minimum_speed: float = .5
var start_velocity

export var rng_min_speed = 50
export var rng_max_speed = 200

var value: int

var decay_time = 4.0
var pop_time = 1.0

func _ready():
	$DecayTimer.start(decay_time)
	direction = randomize_direction()
	speed = randomize_speed()
	_velocity = get_velocity(speed, direction)
	start_velocity = abs(_velocity.x) + abs(_velocity.y)/2 #used to calculate animation slowdown

	match value:
		1:
			if _velocity.x < 0: $AnimationPlayer.play("OneLeft")
			else: $AnimationPlayer.play("OneRight")
		3:
			$AnimationPlayer.play("ThreeRight")
		4:
			$AnimationPlayer.play("FourRight")

func _physics_process(delta):
	if abs(_velocity.x) > minimum_speed and abs(_velocity.y) > minimum_speed:
		var collision = move_and_collide(_velocity * delta)
		if collision:
			#var normal = collision.normal
			#_velocity = get_bounce_velocity(_velocity, normal)
			_velocity *= bounciness
			_velocity = _velocity.bounce(collision.normal)
			if $AnimationPlayer.is_playing():
				$Bounce2D.play()
			
	_velocity.y += gravity * get_physics_process_delta_time()

	var avr_velocity = abs(_velocity.x) + abs(_velocity.y)/2 #used to calculate animation slowdown
	$AnimationPlayer.playback_speed = avr_velocity / start_velocity
	if $AnimationPlayer.playback_speed < .1:
		$AnimationPlayer.stop()

func randomize_direction():
	rng.randomize()
	return Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
	
func randomize_speed():
	rng.randomize()
	return Vector2(rng.randf_range(rng_min_speed, rng_max_speed),rng.randf_range(rng_min_speed, rng_max_speed))
	
func get_velocity(speed, direction) -> Vector2:
	var out: = _velocity
	
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
		"OneRight", "OneLeft": $AnimationPlayer.play("OnePop")
	yield($AnimationPlayer, "animation_finished")
	queue_free()
