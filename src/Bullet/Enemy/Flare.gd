extends Bullet

@onready var FLARE_TRAIL = preload("res://src/Bullet/Enemy/FlareTrail.tscn")
@onready var FLARE_EXPLOSION = preload("res://src/Effect/FlareExplosion.tscn")

@export var explosion_damage: = 2.0


var state = "normal"


func setup():
	speed = 300.0
	rotation_degrees = get_rot(direction)
	$TrailSpawnTimer.start()
	create_flare_trail()

func _physics_process(delta):
	velocity = speed * direction
	move_and_slide()

	var last_collision = get_last_slide_collision()
	if last_collision:
		explode()

	if state == "set_off":
		$AnimationPlayer.speed_scale += delta

func create_flare_trail():
	if state != "explode":
		var flare_trail = FLARE_TRAIL.instantiate()
		flare_trail.global_position = $End.global_position
		w.player_front.add_child(flare_trail)

func explode():
	if state != "explode":
		set_physics_process(false)
		state = "explode"
		$TrailSpawnTimer.stop()
		$DetectExplosionTimer.stop()
		$PlayerDetectionZone.set_deferred("monitoring", false)
		$ExplosionDetector.set_deferred("monitorable", true)
		$ExplosionDetector.set_deferred("monitoring", true)
		$ExplosionDetector.top_level = true
		$ExplosionDetector.global_position = global_position

		var explosion = FLARE_EXPLOSION.instantiate()
		explosion.global_position = global_position
		w.middle_front.add_child(explosion)
		await get_tree().create_timer(0.2).timeout
		queue_free()

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
		var collider = $WorldCast.get_collider()
		if collider is not TileMapLayer and collider.get_collision_layer_value(6):
			print("Armor in the way of explosion")
			collider.blocked.emit($ExplosionDetector, collider)
			return true
		else:
			print("World in way of grenade")
			return true
	else:
		return false

### SIGNALS ###
func _on_CollisionDetector_body_entered(body):
	if body is TileMapLayer:
		if body.tile_set.get_physics_layer_collision_layer(0) == 8: #world (layer value)
			if f.pc(): #and camera gun recoil is true
				f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_wall_distance, camera_recoil_time, camera_recoil_curve)
			explode()

	else: #not TileMapLayer
		#breakable
		if body.get_collision_layer_value(9):
			if f.pc(): #and camera gun recoil is true
				f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_hit_distance, camera_recoil_time, camera_recoil_curve)
			explode()
		#armor
		elif body.get_collision_layer_value(6):
			if f.pc(): #and camera gun recoil is true
				f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_wall_distance, camera_recoil_time, camera_recoil_curve)
			explode()
		#Movable platform
		if body.get_collision_layer_value(4):
			if f.pc(): #and camera gun recoil is true
				f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_wall_distance, camera_recoil_time, camera_recoil_curve)
			explode()


func _on_CollisionDetector_area_entered(area): #TODO: double check breakable piercing
	if area.get_collision_layer_value(18): #enemyhurt
		var blood_dir = get_blood_dir(area.get_parent())
		area.get_parent().hit(damage, blood_dir, $PlayerCollisionDetector, blood_dir, knockback_strength)
		explode()
		if f.pc(): #and camera gun recoil is true
			f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_hit_distance, camera_recoil_time, camera_recoil_curve)
	elif area.get_collision_layer_value(17): #playerhurt
		area.get_parent().hit(damage, get_blood_dir(area.get_parent()), $PlayerCollisionDetector)
		explode()
	elif area.get_collision_layer_value(9): #breakable
		area.get_parent().on_break(break_method)
		if f.pc(): #and camera gun recoil is true
			f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_hit_distance, camera_recoil_time, camera_recoil_curve)
			explode()
	elif area.get_collision_layer_value(4): #world
		if f.pc(): #and camera gun recoil is true
			f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_wall_distance, camera_recoil_time, camera_recoil_curve)
		explode()
	elif area.get_collision_layer_value(6): #armor
		if f.pc(): #and camera gun recoil is true
			f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_wall_distance, camera_recoil_time, camera_recoil_curve)
		explode()

func _on_DetectExplosionTimer_timeout() -> void:
	explode()

func _on_TrailSpawnTimer_timeout() -> void:
	create_flare_trail()

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
			area.get_parent().hit(explosion_damage, knockback_direction, $ExplosionDetector)
	#enemyhurt
	elif area.get_collision_layer_value(18):
		if !is_world_blocking(area):
			var blood_dir = get_blood_dir(area.get_parent())
			area.get_parent().hit(explosion_damage, blood_dir, $ExplosionDetector, blood_dir, knockback_strength)


func _on_PlayerDetectionZone_body_entered(body: Node2D) -> void:
	if state ==  "normal":
		$DetectExplosionTimer.start()
		state = "set_off"
		$AnimationPlayer.play("Blinking")
		$AnimationPlayer.speed_scale = 1.0
