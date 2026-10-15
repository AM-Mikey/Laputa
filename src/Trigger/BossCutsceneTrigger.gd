extends Trigger

@export_file var cutscene_path: String = "res://src/Cutscene/BossCutscene.gd"
@export var boss_id: String = ""

func _ready():
	trigger_type = "boss_cutscene_trigger"
	w.emit_signal("finished_spawn_entities_step")

func _on_body_entered(_body: Node2D) -> void:
	if !spent:
		var cutscene = w.c.add_cutscene(cutscene_path)
		cutscene.boss_arena_rect = $ArenaBoundary.get_global_value()
		cutscene.boss_id = boss_id
		cutscene.start()
		spent = true
