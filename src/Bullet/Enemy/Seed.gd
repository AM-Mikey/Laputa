extends Bullet

var velocity = Vector2.ZERO
var direction = Vector2.ZERO
var projectile_speed: int
var startvelocity


var origin = Vector2.ZERO


func _ready():
	add_to_group("WindBullets")
	$AnimationPlayer.play("RotateLeft")
	
	velocity = getvelocity(projectile_speed, direction)
	startvelocity = abs(velocity.x) + abs(velocity.y)/2 #used to calculate animation slowdown


func _physics_process(delta):
#	if is_on_floor():
#		queue_free()
	
	velocity.y += gravity * delta
			
	var avrvelocity = abs(velocity.x) + abs(velocity.y)/2 #used to calculate animation slowdown
	$AnimationPlayer.playback_speed = avrvelocity / startvelocity
	if $AnimationPlayer.playback_speed < .1:
		$AnimationPlayer.stop()

	if disabled == false:
			move_and_slide(velocity)


func getvelocity(projectile_speed, direction) -> Vector2:
	var out = velocity
	#print("seed dir: ", direction)
	out.x = projectile_speed * direction.x
	out.y += gravity * get_physics_process_delta_time()
	
	if direction.y < 0:
		out.y = projectile_speed * direction.y
	#print(out)
	return out


func _on_CollisionDetector_body_entered(body):
	if disabled == false:
		
		if body.get_collision_layer_bit(0): #player
			var blood_direction = Vector2(floor((body.global_position.x - global_position.x)/10), floor((body.global_position.y - global_position.y)/10))
			body.hit(damage, blood_direction)
			queue_free()
		elif body.get_collision_layer_bit(3): #world
			_fizzle_from_world()


func on_break(method):
	if disabled == false:
		print("destroyed seed")
		_fizzle_from_world()





