extends State

@onready var em = get_parent().get_parent()
@onready var ap = em.get_node("AnimationPlayer")
@onready var hitbox = em.get_node("KickHitbox")

func state_process():
	if not ap.is_playing():
		sm.change_state("Fall")
		return

	em.velocity = Vector2.ZERO
	em.move_and_slide()



func enter():
	em.kicked = true
	ap.play("Kick")
	am.play("enemy_shoot")
	hitbox.monitoring = true
	hitbox.monitorable = true

func exit():
	em.velocity = Vector2.ZERO
	hitbox.monitoring = false
	hitbox.monitorable = false



func _on_KickHitbox_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_value(6): #armor
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)
	elif area.get_collision_layer_value(17): #playerhurt
		area.get_parent().hit(em.kick_damage, Vector2(80 * em.look_dir.x, 0))
	elif area.get_collision_layer_value(9): #breakable
		area.get_parent().on_break()


func _on_KickHitbox_body_entered(body: Node2D) -> void:
	if body.get_collision_layer_value(6): #armor
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)
