extends Trigger

@export_file var cutscene_path: String = "res://src/Cutscene/Cutscene.gd"

func _ready():
	trigger_type = "cutscene_trigger"
	w.emit_signal("finished_spawn_entities_step")

func _on_body_entered(_body: Node2D) -> void:
	if !spent:
		var cutscene = w.c.add_cutscene(cutscene_path)
		cutscene.start()
		spent = true
