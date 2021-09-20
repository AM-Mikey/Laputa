extends Bullet

var velocity = Vector2.ZERO
var direction = Vector2.ZERO
var projectile_speed = 24
var start_velocity

var projectile_range = 64


var origin = Vector2.ZERO


func _ready():
	if direction == Vector2.LEFT:
		rotation_degrees = 0
	if direction == Vector2.RIGHT:
		rotation_degrees = 180
	if direction == Vector2.UP:
		rotation_degrees = 90
	if direction == Vector2.DOWN:
		rotation_degrees = -90


func _physics_process(delta):
	
	velocity = projectile_speed * direction
	
	if disabled == false:
		move_and_slide(velocity)
		var distance_from_origin = origin.distance_to(global_position);
		if distance_from_origin > projectile_range:
			_fizzle_from_range()


#func get_velocity(projectile_speed, direction) -> Vector2: #is this ever used?
#	var out = velocity
#	#print("seed dir: ", direction)
#	out.x = projectile_speed * direction.x
#
#	if direction.y < 0:
#		out.y = projectile_speed * direction.y
#	#print(out)
#	return out


func _on_CollisionDetector_body_entered(body):
	if disabled == false:
		
		if body.get_collision_layer_bit(0): #player
			var blood_direction = Vector2(floor((body.global_position.x - global_position.x)/10), floor((body.global_position.y - global_position.y)/10))
			body.hit(damage, blood_direction)
			queue_free()
		elif body.get_collision_layer_bit(3): #world
			_fizzle_from_world()
