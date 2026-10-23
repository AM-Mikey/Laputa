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

### SIGNALS ###
#func _on_CollisionDetector_body_entered(body):
	#if cool: return
	#if !body is TileMapLayer:
		#if body.get_collision_layer_value(9): #breakable
			#on_break(break_method)
		#elif body.get_collision_layer_value(6): #armor
			#if armor_check(body):
				#queue_free()
				##do_fizzle("armor")
#
#
#func _on_CollisionDetector_area_entered(area):
	#if cool: return
#
	#if area.get_collision_layer_value(18): #enemyhurt
		#var blood_dir = get_blood_dir(area.get_parent())
		#area.get_parent().hit(damage, blood_dir, $PlayerCollisionDetector, blood_dir, knockback_strength)
		#queue_free()
	#elif area.get_collision_layer_value(9): #breakable
		#area.get_parent().on_break(break_method)
		##on_break(break_method) produced two fizzle particles so instead do:
		#queue_free()
	#elif area.get_collision_layer_value(6): #armor
		#queue_free()
		##do_fizzle("armor")


func _on_AnimationPlayer_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Burnout":
		queue_free()
