extends Trigger

const DB = preload("res://src/Dialog/DialogBox.tscn")

var reading = false

@export var text = "" # (String, MULTILINE)

var db

@onready var world = get_tree().get_root().get_node("World")

func _on_body_entered(body):
	active_pc = body.get_parent()
func _on_body_exited(_body):
	active_pc = null

func _input(event):
	if not reading:
		if event.is_action_pressed("inspect") and active_pc != null:
			if not active_pc.disabled and active_pc.can_input and active_pc.mm.current_state == active_pc.mm.states["run"]:
				active_pc.inspect_target = $CollisionShape2D
				reading = true
				for i in get_tree().get_nodes_in_group("DialogBoxes"): #exit old
					i.exit()

				db = DB.instantiate()
				db.connect("dialog_finished", Callable(self, "on_dialog_finished"))
				get_tree().get_root().get_node("World/UILayer").add_child(db)
				db.start_printing_flavor_text(text)


func on_dialog_finished():
	reading = false
