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

export var xp: int

func _ready():
	direction = randomize_direction()
	speed = randomize_speed()
	_velocity = get_velocity(speed, direction)

func _physics_process(delta):
	if abs(_velocity.x) > minimum_speed and abs(_velocity.y) > minimum_speed:
		var collision = move_and_collide(_velocity * delta)
		if collision:
			#var normal = collision.normal
			#_velocity = get_bounce_velocity(_velocity, normal)
			_velocity *= bounciness
			_velocity = _velocity.bounce(collision.normal)
			$BounceSpacial.play()
			
	_velocity.y += gravity * get_physics_process_delta_time()

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
