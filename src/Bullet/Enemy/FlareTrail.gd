extends Bullet

var cool := false
var terminal_vel: = Vector2(0, 400.0)

func setup():
	break_method = "cut"

func _on_physics_process(delta):
	velocity.y = min(velocity.y + gravity * delta, terminal_vel.y)

	var collision = move_and_collide(velocity * delta)
	if collision:
		cool = true
		$AnimationPlayer.play("Burnout")
		$EnemyCollisionDetector.set_deferred("monitoring", false)
		$EnemyCollisionDetector.set_deferred("monitorable", false)

func burnout():
	$AnimationPlayer.play("Burnout")
	$EnemyCollisionDetector.set_deferred("monitoring", false)
	$EnemyCollisionDetector.set_deferred("monitorable", false)


### SIGNALS ###
func _on_CollisionDetector_body_entered(body):
	if body is TileMapLayer:
		if body.tile_set.get_physics_layer_collision_layer(0) == 8: #world (layer value)
			if f.pc(): #and camera gun recoil is true
				f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_wall_distance, camera_recoil_time, camera_recoil_curve)
			burnout()

	else: #not TileMapLayer
		#breakable
		if body.get_collision_layer_value(9):
			if f.pc(): #and camera gun recoil is true
				f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_hit_distance, camera_recoil_time, camera_recoil_curve)
			on_break(break_method)
		#armor
		elif body.get_collision_layer_value(6):
			if f.pc(): #and camera gun recoil is true
				f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_wall_distance, camera_recoil_time, camera_recoil_curve)
			burnout()
		#Movable platform
		if body.get_collision_layer_value(4):
			if f.pc(): #and camera gun recoil is true
				f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_wall_distance, camera_recoil_time, camera_recoil_curve)
			burnout()


func _on_CollisionDetector_area_entered(area): #TODO: double check breakable piercing
	if area.get_collision_layer_value(18): #enemyhurt
		var blood_dir = get_blood_dir(area.get_parent())
		area.get_parent().hit(damage, blood_dir, $PlayerCollisionDetector, blood_dir, knockback_strength)
		if f.pc(): #and camera gun recoil is true
			f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_hit_distance, camera_recoil_time, camera_recoil_curve)
		queue_free()
	elif area.get_collision_layer_value(17): #playerhurt
		area.get_parent().hit(damage, get_blood_dir(area.get_parent()), $PlayerCollisionDetector)
		queue_free()
	elif area.get_collision_layer_value(9): #breakable
		area.get_parent().on_break(break_method)
		if f.pc(): #and camera gun recoil is true
			f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_hit_distance, camera_recoil_time, camera_recoil_curve)
		queue_free()
	elif area.get_collision_layer_value(4): #world
		if f.pc(): #and camera gun recoil is true
			f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_wall_distance, camera_recoil_time, camera_recoil_curve)
		burnout()
	elif area.get_collision_layer_value(6): #armor
		if f.pc(): #and camera gun recoil is true
			f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_wall_distance, camera_recoil_time, camera_recoil_curve)
		burnout()


func _on_AnimationPlayer_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Burnout":
		queue_free()
