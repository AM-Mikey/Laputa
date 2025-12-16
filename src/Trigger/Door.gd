extends Trigger

const TRANSITION = preload("res://src/Effect/Transition/TransitionIris.tscn")

signal level_change(level, door_index)

@export var same_level := false
@export var level: String
@export var door_index: int = 0
@export var same_level_next_index: int = 0
@export var locked = false

func _ready():
	var _err = connect("level_change", Callable(w, "change_level_via_trigger"))
	trigger_type = "door"


func _on_body_entered(body):
	active_pc = body.get_parent()
func _on_body_exited(_body):
	active_pc = null


func _input(event):
	if event.is_action_pressed("inspect") and active_pc != null:
		if active_pc.is_on_floor() and active_pc.can_input:
			if not locked:
				enter_door()
			else:
				if active_pc.inventory.has("Key"):
					var index = active_pc.inventory.find("Key") #TODO: have door store a specific key
					active_pc.inventory.remove(index)
					enter_door()
				else:
					am.play("locked")


func enter_door():
	active_pc.can_input = false
	active_pc.inspect_target = self
	active_pc.mm.change_state("inspect")
	active_pc.move_to(global_position + Vector2($CollisionShape2D.shape.size.x * 0.5, $CollisionShape2D.shape.size.y))

	am.play("door")
	am.fade_music()

	var transition = TRANSITION.instantiate()
	if w.bl.has_node("TransitionIris"):
		w.bl.get_node("TransitionIris").free()
	w.bl.add_child(transition)

	await transition.get_node("AnimationPlayer").animation_finished

	active_pc.mm.change_state("run")

	if same_level:
		emit_signal("level_change", w.current_level.scene_file_path, same_level_next_index)
	else:
		var level_path = str("res://src/Level/" + level + ".tscn")
		if !FileAccess.file_exists(level_path):
			printerr("ERROR: No Level With Name: ", level)
			return
		emit_signal("level_change", level_path, door_index)
