extends Actor

var small = load("res://src/Actor/XpSmall.tres")
var medium = load("res://src/Actor/XpMedium.tres")
var large = load("res://src/Actor/XpLarge.tres")

var rng = RandomNumberGenerator.new()
var direction
export var bounciness: float = .75
export var minimum_speed: float = .05

export var rng_min_speed = 50
export var rng_max_speed = 200

var value: int

func _ready():
	direction = randomize_direction()
	speed = randomize_speed()
	velocity = getvelocity(speed, direction)

	if value <= 1:
		$AnimationPlayer.play("Small")
	elif value <= 5:
		$AnimationPlayer.play("Medium")
	else:
		$AnimationPlayer.play("Large")

func _physics_process(delta):
	if abs(velocity.x) > minimum_speed and abs(velocity.y) > minimum_speed:
		var collision = move_and_collide(velocity * delta)
		if collision:
			#var normal = collision.normal
			#velocity = get_bouncevelocity(velocity, normal)
			velocity *= bounciness
			velocity = velocity.bounce(collision.normal)
			$BounceSpacial.play()
			
	velocity.y += gravity * get_physics_process_delta_time()

func randomize_direction():
	rng.randomize()
	return Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
	
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


func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()
