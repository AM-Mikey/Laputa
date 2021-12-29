extends Trigger

const TRANSITION = preload("res://src/Effect/Transition/TransitionWipe.tscn")

signal level_change(level, door_index)

export var level: String
export var door_index: int = 0
export var direction = Vector2.RIGHT

func _ready():
	var _err = connect("level_change", w, "on_level_change")
	trigger_type = "load_zone"
	add_to_group("LevelTriggers")
	add_to_group("LoadZones")


func _on_body_entered(body):
	active_pc = body
	enter_load_zone()
func _on_body_exited(_body):
	pass


func enter_load_zone():
	active_pc.disable()
	active_pc.move_to(Vector2((position.x + (direction.x * 16)), position.y)) #active_pc.move_to(position)
	
	am.play("door")
	
	var transition = TRANSITION.instance()
	match direction:
		Vector2.LEFT: transition.animation = "WipeInLeft"
		Vector2.RIGHT: transition.animation = "WipeInRight"
		Vector2.UP: transition.animation = "WipeInUp"
		Vector2.DOWN: transition.animation = "WipeInDown"

	if w.get_node("UILayer").has_node("TransitionWipe"):
		w.get_node("UILayer/TransitionWipe").free()
	w.get_node("UILayer").add_child(transition)

	yield(transition.get_node("AnimationPlayer"), "animation_finished")
	emit_signal("level_change", level, door_index)
