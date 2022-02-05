extends Bullet

var texture: StreamTexture
var texture_index: int
var collision_shape: RectangleShape2D


var minimum_speed: float = 24
var bounciness = .6
var explosion_time = 2.5
var start_velocity
var touched_floor = false
var player_on_floor = false
var player_held_down = false
var zero_speed_last_frame = false

func _ready():
	break_method = "burn"
	default_area_collision = false
	default_body_collision = false
	
	$ExplosionDetector.scale = Vector2.ZERO
	$ExplosionDetector.set_collision_mask_bit(0, false) #player
	$ExplosionDetector.set_collision_mask_bit(1, false) #enemy
	$ExplosionDetector.set_collision_mask_bit(8, false) #destructable
	
	var player = get_tree().get_root().get_node("World/Juniper")
	player_on_floor = player.is_on_floor()
	player_held_down = Input.is_action_pressed("look_down")
	
	velocity = get_initial_velocity(speed, direction)
	start_velocity = abs(velocity.x) + abs(velocity.y)/2 #used to calculate animation slowdown
	$Timer.start(explosion_time)



func _physics_process(delta):
	if is_on_floor():
		touched_floor = true
	
	if abs(velocity.x) > minimum_speed or abs(velocity.y) > minimum_speed: #check or not and
		if disabled == false:
			if velocity.x < 0:
				$AnimationPlayer.play("FlipLeft")
			else:
				$AnimationPlayer.play("FlipRight")
			
			var collision = move_and_collide(velocity * delta)
			if collision:
				velocity *= bounciness
				velocity = velocity.bounce(collision.normal)
				$Bounce2D.play()
	
	else: #if it ever gets below the minimum speed in x or y
		if zero_speed_last_frame:
			velocity = Vector2.ZERO
		else:
			zero_speed_last_frame = true
		
		

	velocity.y += gravity * delta
			
	var avr_velocity = abs(velocity.x) + abs(velocity.y)/2 #used to calculate animation slowdown
	$AnimationPlayer.playback_speed = avr_velocity / start_velocity
	if $AnimationPlayer.playback_speed < .1:
		$AnimationPlayer.stop()

func get_initial_velocity(scoped_projectile_speed, scoped_direction) -> Vector2:
	var out = velocity

	out.x = scoped_projectile_speed * scoped_direction.x
	out.y = scoped_projectile_speed * scoped_direction.y
	
	if player_on_floor and player_held_down:  #look down on ground
		out.y -= 50
	elif player_held_down: #look down midair
		pass
	else:
		out.y -= 100 #give us some ups to start with

	#print(out)
	return out
	
func _on_CollisionDetector_body_entered(body):
	if disabled == false:
		if body.get_collision_layer_bit(1): #enemy
			var blood_direction = Vector2(floor((body.global_position .x - global_position.x)/10), floor((body.global_position.y - global_position.y)/10))
			if not touched_floor:
				body.hit(damage, blood_direction)
			else:
				body.hit(damage/2, blood_direction)
			queue_free()


func _on_Timer_timeout():
	$ExplosionDetector.set_collision_mask_bit(0, true)
	$ExplosionDetector.set_collision_mask_bit(1, true)
	$ExplosionDetector.set_collision_mask_bit(8, true)
	$AnimationPlayer.stop()
	
	var explosion = load("res://src/Effect/GrenadeExplosion.tscn").instance()
	explosion.position = position
	
	if $ExplosionDetector/CollisionShape2D.shape.radius == 32:
		explosion.size = "Small"
	if $ExplosionDetector/CollisionShape2D.shape.radius == 48:
		explosion.size = "Medium"
	if $ExplosionDetector/CollisionShape2D.shape.radius == 64:
		explosion.size = "Large"
	get_tree().get_root().get_node("World/Front").add_child(explosion)
	
	$Tween.interpolate_property($ExplosionDetector, "scale", $ExplosionDetector.scale, Vector2(1, 1), .1, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()
	yield(get_tree().create_timer(0.1), "timeout")
	visible = false
	queue_free()

func _on_ExplosionDetector_body_entered(body):
	if disabled == false:
		if body.get_collision_layer_bit(0): #player
			var knockback_direction = Vector2(sign(body.global_position.x - global_position.x), 0) #sign(body.global_position.y - global_position.y)
			body.hit(damage/4, knockback_direction)
		
		if body.get_collision_layer_bit(1): #enemy
			var blood_direction = Vector2(floor((body.global_position.x - global_position.x)/10), floor((body.global_position.y - global_position.y)/10))
			body.hit(damage/4, blood_direction)
		elif body.get_collision_layer_bit(8): #breakable
			body.on_break("fire")
			print("ok")
