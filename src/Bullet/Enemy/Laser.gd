extends Bullet

var projectile_speed = 24
var start_velocity

var projectile_range = 64




func _ready():
	is_enemy_bullet = true
	match direction:
		Vector2.LEFT: rotation_degrees = 0
		Vector2.RIGHT: rotation_degrees = 180
		Vector2.UP: rotation_degrees = 90
		Vector2.DOWN: rotation_degrees = -90


func _physics_process(_delta):
	velocity = projectile_speed * direction
	
	if disabled == false:
		move_and_slide(velocity)
		var distance_from_origin = origin.distance_to(global_position);
		if distance_from_origin > projectile_range:
			fizzle("range")
