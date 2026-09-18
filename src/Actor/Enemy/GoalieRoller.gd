extends EnemyGoalie

## Specialized Goalie that can also kick Roller

func setup() -> void:
	difficulty = 1
	super.setup()
	$Sprite2D.modulate = Color.GREEN
	$DeflectDetector.set_collision_mask_value(2, true)
	deflect_hitbox.set_collision_mask_value(2, true)

### SIGNALS ###
func _on_DeflectHitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Roller") && body.get_collision_layer_value(2) && allow_to_deflect: #enemy

		var player = f.pc()
		if !player: return
		var dir: = body.global_position.direction_to(player.global_position + Vector2(0, -15))
		print("Kick: ", body, ": ", body.global_position, " -> ", player.global_position, " = ", dir)
		var knockback = dir * kick_force * 2.0
		#if dir.y < 0.5:
			#knockback.y = -100.0
		print("Knockback: ",  knockback)
		#body.hit(0.0, Vector2.ZERO, kick_hitbox, dir, kick_force)
		body.knockback_velocity = knockback
		body.move_dir.x = 1.0 if dir.x >= 0 else -1.0
		var tween = body.create_tween()
		tween.tween_property(body, "velocity:x", knockback.x, 0.1)
		#tween.tween_property(body, "velocity", knockback, 3.0)
	elif body.get_collision_layer_value(7) || (body.get_collision_layer_value(14) && allow_to_deflect):
		var player = f.pc()
		if !player: return
		#var tween = body.create_tween()
		if body.get_collision_layer_value(7):
			body.change_side(false)
		var dir: = body.global_position.direction_to(player.global_position + Vector2(0, -15))
		#tween.tween_property(body, "velocity", dir * kick_force, 0.1)
		#tween.tween_property(body, "velocity", dir * kick_force, 3.0)
		body.process_mode = Node.PROCESS_MODE_DISABLED
		body.direction = dir
		body.velocity = dir * kick_force
		await get_tree().physics_frame
		body.process_mode = Node.PROCESS_MODE_INHERIT


func _on_PlayerDetector_body_entered(body: Node2D) -> void:
	allow_to_deflect = true

func _on_PlayerDetector_body_exited(body: Node2D) -> void:
	allow_to_deflect = false
