extends Area2D


export var id: String

var connected_enemies = 0

signal cue

func _ready():
	var enemies = get_tree().get_nodes_in_group("Enemies")
	for e in enemies:
		if e.id == id:
			connect("cue", e, "on_cue")
			connected_enemies += 1
	
	if connected_enemies == 0:
		queue_free()

func _on_EnemyCue_body_entered(body):
	emit_signal("cue")
	queue_free()
