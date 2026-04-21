extends Trigger

signal cue

func _ready(): #Reminder: no function called can use await
	trigger_type = "enemy_cue"
	w.emit_signal("finished_spawn_entities_step")

func _on_EnemyCue_body_entered(_body):
	var enemies = get_tree().get_nodes_in_group("Enemies")
	for e in enemies:
		if e.id == id:
			connect("cue", Callable(e, "on_cue"))
	emit_signal("cue")
	queue_free()
