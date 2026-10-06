extends Trigger

const cutscene_scene = preload("res://src/Cutscene/BossTestCutscene.tscn")

func _ready() -> void:
	trigger_type = "boss_room"
	w.emit_signal("finished_spawn_entities_step")

func _on_body_entered(body: Node2D) -> void:
	if !spent:
		var cutscene = cutscene_scene.instantiate()
		w.farthest_back.add_child(cutscene)
		spent = true
