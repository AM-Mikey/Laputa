extends Bullet

var texture: CompressedTexture2D
var texture_index: int
var collision_shape: RectangleShape2D

var minimum_speed: float = 6
var bounciness = .6
var explosion_time = 2.5
var start_velocity
var touched_floor = false

@onready var pc = f.pc()
@onready var pc_on_floor = pc.is_on_floor()
@onready var pc_held_down = Input.is_action_pressed("look_down") and pc.can_input



func _ready():
	break_method = "burn"
	$ExplosionDetector.scale = Vector2.ZERO
	$ExplosionDetector/CollisionShape2D.set_deferred("disabled", true)
	velocity = get_initial_velocity(speed, direction)
	start_velocity = abs(velocity.x) + abs(velocity.y) / 2.0 #used to calculate animation slowdown
	$Timer.start(explosion_time)



func _physics_process(delta):
	if disabled: return
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
	#breakable
	if body.get_collision_layer_value(9):
		body.on_break("fire")


func _on_ExplosionDetector_area_entered(area):
	if disabled: return
	#playerhurt
	if area.get_collision_layer_value(17):
		var knockback_direction = Vector2(sign(area.get_parent().global_position.x - global_position.x), 0)
		area.get_parent().hit(int(damage/4.0), knockback_direction)
	#enemyhurt
	elif area.get_collision_layer_value(18):
		area.get_parent().hit(int(damage/4.0), get_blood_dir(area.get_parent()))
