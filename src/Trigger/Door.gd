extends Trigger

const TRANSITION = preload("res://src/Effect/Transition/TransitionIris.tscn")

signal level_change(level, door_index)

export var level: String
export var door_index: int = 0
export var locked = false

func _ready():
	var _val = connect("level_change", w, "on_level_change") #TODO a better way of not returning this
	trigger_type = "door"
	add_to_group("LevelTriggers")
	add_to_group("Doors")


func _on_body_entered(body):
	active_pc = body
func _on_body_exited(_body):
	active_pc = null


func _input(event):
	if event.is_action("inspect") and active_pc != null:
		if not active_pc.disabled and active_pc.is_on_floor():
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
	active_pc.mm.change_state("inspect")
	active_pc.disable()
	active_pc.move_to(position)
	
	am.play("door")
	am.fade_music()
	
	var transition = TRANSITION.instance()
	if w.get_node("UILayer").has_node("TransitionIris"):
		w.get_node("UILayer/TransitionIris").free()
	w.get_node("UILayer").add_child(transition)
	
	yield(transition.get_node("AnimationPlayer"), "animation_finished")
	#active_pc.inspecting = false
	emit_signal("level_change", load(level), door_index)
