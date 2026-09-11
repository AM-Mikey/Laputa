extends EnemyGoalie

var kick_next_state = ""

func _setup():
	pass

### STATES ###
func enter_kick(prev_state):
	super.enter_kick(prev_state)
	if prev_state in ["idle", "active"]:
		kick_next_state = "idle"
	elif prev_state == "rise":
		kick_next_state = "fall"


func do_kick(_delta):
	if not ap.is_playing():
		change_state(kick_next_state)
		return

	velocity = Vector2.ZERO
	move_and_slide()

### SIGNALS ###
func _on_KickDectector_body_entered(body):
	if state == "idle":
		if body.get_collision_layer_value(7) || body.get_collision_layer_value(14) \
		|| body.get_collision_layer_value(2):
			change_state("kick")
	elif state == "rise":
		change_state("kick")
	elif state == "fall" && $KickGraceTimer.time_left > 0.0:
		change_state("kick")

func _on_KickHitbox_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_value(6): #armor
		kick_hitbox.set_deferred("monitoring", false)
		kick_hitbox.set_deferred("monitorable", false)
	elif area.get_collision_layer_value(17): #playerhurt
		area.get_parent().hit(kick_damage, Vector2(80 * look_dir.x, 0), kick_hitbox)
	elif area.get_collision_layer_value(9): #breakable
		area.get_parent().on_break("cut")



func _on_KickHitbox_body_entered(body: Node2D) -> void:
	if body.get_collision_layer_value(6): #armor
		kick_hitbox.set_deferred("monitoring", false)
		kick_hitbox.set_deferred("monitorable", false)
	elif body.get_collision_layer_value(2): #enemy
		var player = f.pc()
		if !player: return
		var dir: = global_position.direction_to(player.global_position)
		body.hit(0.0, Vector2.ZERO, kick_hitbox, dir, 200.0)
	elif body.get_collision_layer_value(7) || body.get_collision_layer_value(14):
		var player = f.pc()
		if !player: return
		var tween = body.create_tween()
		var dir: = global_position.direction_to(player.global_position)
		tween.tween_property(body, "velocity", dir * 200.0, 0.1)
		tween.tween_interval(3.0)
