extends Bullet

var texture: StreamTexture
var texture_index: int
var collision_shape: RectangleShape2D

var velocity = Vector2.ZERO
var direction = Vector2.ZERO
var projectile_speed = Vector2.ZERO

var projectile_range: int

var max_spread_distance = 7

var origin = Vector2.ZERO


var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	var spread_distance = int(rng.randf_range(max_spread_distance * -1, max_spread_distance))
	
	match direction:
		Vector2.LEFT:
			rotation_degrees = 0
			global_position.y += spread_distance
		Vector2.RIGHT:
			rotation_degrees = 180
			global_position.y += spread_distance
		Vector2.UP:
			rotation_degrees = 90
			global_position.x += spread_distance
		Vector2.DOWN:
			rotation_degrees = -90
			global_position.x += spread_distance


func _physics_process(_delta):
	
	velocity = projectile_speed * direction
	
	if disabled == false:
		move_and_slide(velocity)
		var distance_from_origin = origin.distance_to(global_position);
		if distance_from_origin > projectile_range:
			_fizzle_from_range()
