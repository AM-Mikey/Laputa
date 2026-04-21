extends Trigger

const DB = preload("res://src/Dialog/DialogBox.tscn")

@export var text = "" # (String, MULTILINE)

var reading = false
var db

@onready var world = get_tree().get_root().get_node("World")

func _ready(): #Reminder: no function called can use await
	trigger_type = "flavor_text"
	w.emit_signal("finished_spawn_entities_step")

func _input(event):
	if !reading: return
	if event.is_action_pressed("inspect") and active_pc != null:
		if not active_pc.disabled and inp.can_act and active_pc.mm.current_state == active_pc.mm.states["run"]:
			active_pc.inspect_target = $CollisionShape2D
			reading = true
			for i in get_tree().get_nodes_in_group("DialogBoxes"): #exit old
				i.exit()

			db = DB.instantiate()
			db.connect("dialog_finished", Callable(self, "on_dialog_finished"))
			w.dll.add_child(db)
			db.start_printing_flavor_text(text)

func on_dialog_finished():
	reading = false

### SIGNALS

func _on_body_entered(body):
	active_pc = body.get_parent()
func _on_body_exited(_body):
	active_pc = null
