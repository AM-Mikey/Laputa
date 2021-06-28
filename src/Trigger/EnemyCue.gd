extends Area2D

signal cue

export var id: String

func _on_EnemyCue_body_entered(body):
	var enemies = get_tree().get_nodes_in_group("Enemies")
	for e in enemies:
		if e.id == id:
			connect("cue", e, "on_cue")
	emit_signal("cue")
	queue_free()
