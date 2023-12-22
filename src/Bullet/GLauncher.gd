extends Bullet

var texture: CompressedTexture2D
var texture_index: int
var collision_shape: RectangleShape2D

var minimum_speed: float = 6
var bounciness = .6
var explosion_time = 2.5
var start_velocity
var touched_floor = false

@onready var pc = get_tree().get_root().get_node("World/Juniper")
@onready var pc_on_floor = pc.is_on_floor()
@onready var pc_held_down = Input.is_action_pressed("look_down")



func _ready():
	break_method = "burn"
	
	$ExplosionDetector.scale = Vector2.ZERO
	$ExplosionDetector.set_collision_mask_value(0, false) #player
	$ExplosionDetector.set_collision_mask_value(1, false) #enemy
	$ExplosionDetector.set_collision_mask_value(8, false) #destructable
	
	velocity = get_initial_velocity(speed, direction)
	start_velocity = abs(velocity.x) + abs(velocity.y)/2 #used to calculate animation slowdown
	$Timer.start(explosion_time)



func _physics_process(delta):
	if not disabled:
		velocity.y += gravity * delta
		
		if velocity.x < 0:
			$AnimationPlayer.play("FlipLeft")
		else:
			$AnimationPlayer.play("FlipRight")
		
		var collision = move_and_collide(velocity * delta)
		if collision:
			if abs(velocity.y) > minimum_speed:
				velocity *= bounciness
				velocity = velocity.bounce(collision.get_normal())
				am.play("gun_grenade_bounce", self)
			else:
				velocity = Vector2.ZERO
	
	var avr_velocity = abs(velocity.x) + abs(velocity.y)/2 #used to calculate animation slowdown
	$AnimationPlayer.speed_scale = avr_velocity / start_velocity
	if $AnimationPlayer.speed_scale < .1:
		$AnimationPlayer.stop()

### GETTERS ###

func get_initial_velocity(scoped_projectile_speed, scoped_direction) -> Vector2:
	var out = velocity

	out.x = scoped_projectile_speed * scoped_direction.x
	out.y = scoped_projectile_speed * scoped_direction.y
	
	if pc_on_floor and pc_held_down:  #look down on ground
		out.y -= 50
	elif pc_held_down: #look down midair
		pass
	else:
		out.y -= 100 #give us some ups to start with

	return out



### SIGNALS ###

func _on_CollisionDetector_body_entered(body): #shadows
	if disabled: return
	#enemy
	if body.get_collision_layer_value(2): 
		if not touched_floor:
			body.hit(damage, get_blood_dir(body))
		else:
			body.hit(int(damage/2.0), get_blood_dir(body))
		queue_free()

func _on_CollisionDetector_area_entered(_area): #shadows
	pass



func _on_Timer_timeout():
	$ExplosionDetector.set_collision_mask_value(0, true)
	$ExplosionDetector.set_collision_mask_value(1, true)
	$ExplosionDetector.set_collision_mask_value(8, true)
	$AnimationPlayer.stop()
	
	var explosion = load("res://src/Effect/GrenadeExplosion.tscn").instantiate()
	explosion.position = position
	
	if $ExplosionDetector/CollisionShape2D.shape.radius == 32:
		explosion.size = "Small"
	if $ExplosionDetector/CollisionShape2D.shape.radius == 48:
		explosion.size = "Medium"
	if $ExplosionDetector/CollisionShape2D.shape.radius == 64:
		explosion.size = "Large"
	get_tree().get_root().get_node("World/Front").add_child(explosion)
	
	
	var tween = get_tree().create_tween()
	tween.tween_property($ExplosionDetector, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	queue_free()

func _on_ExplosionDetector_body_entered(body):
	if disabled: return
	#player
	if body.get_collision_layer_value(1): 
		var knockback_direction = Vector2(sign(body.global_position.x - global_position.x), 0) #sign(body.global_position.y - global_position.y)
		body.hit(int(damage/4.0), knockback_direction)
	#enemy
	elif body.get_collision_layer_value(2):
		body.hit(int(damage/4.0), get_blood_dir(body))
	#breakable
	elif body.get_collision_layer_value(9): 
		body.on_break("fire")
