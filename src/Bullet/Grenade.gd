extends Bullet

var texture: StreamTexture
var texture_index: int
var collision_shape: RectangleShape2D

var velocity = Vector2.ZERO
var direction = Vector2.ZERO
var projectile_speed: int

var projectile_range: int

var origin = Vector2.ZERO

var minimum_speed: float = 1
var bounciness = .6
var explosion_time = 2.5
var start_velocity

func _ready():
	$ExplosionDetector.scale = Vector2.ZERO
	velocity = get_velocity(projectile_speed, direction)
	start_velocity = abs(velocity.x) + abs(velocity.y)/2
	$Timer.start(explosion_time)
	$AnimationPlayer.play("Flip")

func _physics_process(delta):
	if abs(velocity.x) > minimum_speed and abs(velocity.y) > minimum_speed:
		if disabled == false:
			var collision = move_and_collide(velocity * delta)
			if collision:
				velocity *= bounciness
				velocity = velocity.bounce(collision.normal)
				$Bounce2D.play()
			
	velocity.y += gravity * delta
			
	var avr_velocity = abs(velocity.x) + abs(velocity.y)/2
	$AnimationPlayer.playback_speed = avr_velocity / start_velocity
	if $AnimationPlayer.playback_speed < .1:
		$AnimationPlayer.stop()
			
	#		var distance_from_origin = origin.distance_to(global_position);
	#		if distance_from_origin > projectile_range:
	#			visible = false
	#			disabled = true
	#			_fizzle_from_range()


func get_velocity(projectile_speed, direction) -> Vector2:
	var out = velocity

	print(direction)

	out.x = projectile_speed * direction.x
	out.y += gravity * get_physics_process_delta_time()
	if direction.y == -1.0:
		out.y = projectile_speed * direction.y
	print(out)
	return out
	
func _on_CollisionDetector_body_entered(body):
	if disabled == false:
		if body.get_collision_layer_bit(1): #enemy
			var blood_direction = Vector2(floor((body.global_position.x - global_position.x)/10), floor((body.global_position.y - global_position.y)/10))
			body.hit(damage, blood_direction)
			queue_free()


func _on_Timer_timeout():
	$AnimationPlayer.stop()
	$Tween.interpolate_property($ExplosionDetector, "scale", $ExplosionDetector.scale, Vector2(1, 1), .1, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()
	yield(get_tree().create_timer(0.1), "timeout")
	visible = false
	queue_free()

func _on_ExplosionDetector_body_entered(body):
	if disabled == false:
		if body.get_collision_layer_bit(1): #enemy
			var blood_direction = Vector2(floor((body.global_position.x - global_position.x)/10), floor((body.global_position.y - global_position.y)/10))
			body.hit(damage, blood_direction)
