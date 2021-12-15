extends Area2D

var damage = 2

var active_pc = null

func _on_Spikes_body_entered(body):
	active_pc = body
	do_damage()

func _on_Spikes_body_exited(body):
	active_pc = null


func _physics_process(delta):
	if active_pc != null:
		if not active_pc.invincible:
			do_damage()


func do_damage():
	active_pc.hit(damage, Vector2.ZERO)
