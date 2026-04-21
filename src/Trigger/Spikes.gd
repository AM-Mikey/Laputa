extends Trigger

var damage = 2

func _ready(): #Reminder: no function called can use await
	trigger_type = "spikes"
	w.emit_signal("finished_spawn_entities_step")

func _do_damage():
	active_pc.hit(damage, Vector2.ZERO)



### SIGNALS

func _on_body_entered(body):
	active_pc = body.get_parent()
	_do_damage()

func _on_body_exited(_body):
	active_pc = null

func _physics_process(_delta):
	if active_pc != null:
		if not active_pc.invincible:
			_do_damage()
