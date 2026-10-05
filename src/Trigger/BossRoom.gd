extends Trigger

func _ready() -> void:
	trigger_type = "boss_room"
	w.emit_signal("finished_spawn_entities_step")


func _on_body_entered(body: Node2D) -> void:
	if !spent:
		print(self)
		spent = true
		ms.progress_main_mission.call_deferred()
