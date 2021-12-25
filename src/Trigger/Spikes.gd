extends Trigger

var damage = 2

func _on_body_entered(body):
	active_pc = body
	_do_damage()

func _on_body_exited(body):
	active_pc = null

func _physics_process(delta):
	if active_pc != null:
		if not active_pc.invincible:
			_do_damage()

func _do_damage():
	active_pc.hit(damage, Vector2.ZERO)
