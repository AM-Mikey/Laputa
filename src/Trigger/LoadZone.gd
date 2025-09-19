extends Trigger

const TRANSITION = preload("res://src/Effect/Transition/TransitionWipe.tscn")

signal level_change(level, door_index)

enum Direction {LEFT, RIGHT, UP, DOWN}

@export var level: String
@export var door_index: int = 0
@export var direction: Direction = Direction.RIGHT

func _ready():
	var _err = connect("level_change", Callable(w, "change_level_via_trigger"))
	trigger_type = "load_zone"


func _on_body_entered(body):
	active_pc = body.get_parent()
	enter_load_zone()
func _on_body_exited(_body):
	pass


func enter_load_zone(): #see if you need the inspect state
	active_pc.can_input = false
	match direction:
		Direction.LEFT:
			active_pc.move_to(Vector2(position.x - 16, position.y))
		Direction.RIGHT:
			active_pc.move_to(Vector2(position.x + 16, position.y))
		Direction.UP:
			pass
		Direction.DOWN:
			pass
	
	
	
	am.play("door")
	am.fade_music()
	
	var transition = TRANSITION.instantiate()
	match direction:
		Direction.LEFT: transition.animation = "WipeInLeft"
		Direction.RIGHT: transition.animation = "WipeInRight"
		Direction.UP: transition.animation = "WipeInUp"
		Direction.DOWN: transition.animation = "WipeInDown"

	if w.bl.has_node("TransitionWipe"):
		w.get_node("BlackoutLayer/TransitionWipe").free()
	w.bl.add_child(transition)

	await transition.get_node("AnimationPlayer").animation_finished
	
	active_pc.mm.change_state("run")
	var level_path = str("res://src/Level/" + level + ".tscn")
	if !FileAccess.file_exists(level_path):
		printerr("ERROR: No Level With Name: ", level)
		return
	emit_signal("level_change", level_path, door_index)
