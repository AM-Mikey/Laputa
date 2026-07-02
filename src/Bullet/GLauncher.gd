extends Bullet

var texture: CompressedTexture2D
var texture_index: int
var collision_shape: RectangleShape2D

var minimum_speed := 6.0
var bounciness := 0.6
var explosion_time = 2.5
var start_avg_vel: float
var touched_floor = false


@onready var pc = f.pc()
@onready var pc_on_floor = pc.is_on_floor()
@onready var pc_held_down = Input.is_action_pressed("look_down") and inp.can_act



func setup():
	break_method = "burn"
	is_wind_affected = true
	$ExplosionDetector.scale = Vector2.ZERO
	$ExplosionDetector/CollisionShape2D.set_deferred("disabled", true)
	velocity = get_initial_velocity(speed, direction)
	start_avg_vel = (abs(velocity.x) + abs(velocity.y)) / 2.0 #used to calculate animation slowdown
	$Timer.start(explosion_time)
	if velocity.x < 0:
		$AnimationPlayer.play("FlipLeft")
	else:
		$AnimationPlayer.play("FlipRight")


func _on_physics_process(delta):
	velocity.y += gravity * delta
	var collision = move_and_collide(velocity * delta)
	if collision:
		if abs(velocity.y) > minimum_speed:
			velocity *= bounciness
			velocity = velocity.bounce(collision.get_normal())
			am.play("gun_grenade_bounce", self)
		else:
			velocity = Vector2.ZERO
		if velocity.x < 0:
			$AnimationPlayer.play("FlipLeft")
		else:
			$AnimationPlayer.play("FlipRight")

	if wind_areas_inside.size() != 0: #Inside Wind
		if velocity.y < 0:
			velocity.y *= 0.9

	var avg_velocity = abs(velocity.x) + abs(velocity.y) / 2.0 #used to calculate animation slowdown
	$AnimationPlayer.speed_scale = avg_velocity / start_avg_vel
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


func is_world_blocking(target) -> bool:
	var target_center_global_position: Vector2
	var target_shape : CollisionShape2D #NOTE: only works on CollisionShape2D
	for c in target.get_children():
		if c is CollisionShape2D:
			target_shape = c #NOTE: gets the LAST collisionshape
	if target_shape:
		target_center_global_position = target_shape.global_position
	else:
		printerr("ERROR: Cannot find child CollisionShape2D in target: ", target)
	$WorldCast.target_position = to_local(target_center_global_position)
	$WorldCast.force_raycast_update()
	if $WorldCast.is_colliding():
		print("World in way of grenade")
		return true
	else:
		return false



### SIGNALS ###

func _on_CollisionDetector_body_entered(body):
	if body is TileMapLayer:
		if body.tile_set.get_physics_layer_collision_layer(0) == 8: #world (layer value)
			touched_floor = true

func _on_CollisionDetector_area_entered(area): #shadows
	#enemyhurt
	if area.get_collision_layer_value(18):
		if not touched_floor:
			area.get_parent().hit(damage, get_blood_dir(area.get_parent()))
		else:
			area.get_parent().hit(int(damage/2.0), get_blood_dir(area.get_parent()))
		queue_free()

func _on_Timer_timeout():
	$ExplosionDetector/CollisionShape2D.set_deferred("disabled", false)
	$AnimationPlayer.stop()

	var explosion = load("res://src/Effect/GrenadeExplosion.tscn").instantiate()
	explosion.position = position

	if $ExplosionDetector/CollisionShape2D.shape.radius == 32: #Brotha EWWWW
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
	#breakable
	if body.get_collision_layer_value(9):
		if !is_world_blocking(body):
			body.on_break("fire")


func _on_ExplosionDetector_area_entered(area):
	#playerhurt
	if area.get_collision_layer_value(17):
		if !is_world_blocking(area):
			var knockback_direction = Vector2(sign(area.get_parent().global_position.x - global_position.x), 0)
			area.get_parent().hit(int(damage/4.0), knockback_direction)
	#enemyhurt
	elif area.get_collision_layer_value(18):
		if !is_world_blocking(area):
			area.get_parent().hit(int(damage/4.0), get_blood_dir(area.get_parent()))
