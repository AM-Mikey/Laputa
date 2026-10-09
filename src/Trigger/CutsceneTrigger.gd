extends Trigger

@export_file var cutscene_path: String = "res://src/Cutscene/BossTestCutscene.tscn"

func _ready():
	trigger_type = "cutscene_trigger"
	w.emit_signal("finished_spawn_entities_step")

func _on_body_entered(_body: Node2D) -> void:
	if !spent:
		var cutscene_scene = load(cutscene_path)
		var cutscene = cutscene_scene.instantiate()
		w.farthest_back.add_child(cutscene)
		spent = true
