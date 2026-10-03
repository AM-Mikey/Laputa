extends Trigger

const DB = preload("res://src/Dialog/DialogBox.tscn")

@export var text = "" # (String, MULTILINE)

var reading = false
var db

func _ready(): #Reminder: no function called can use await
	trigger_type = "flavor_text"
	w.emit_signal("finished_spawn_entities_step")

func player_interact(p: Player):
	if reading: return
	p.inspect_target = $CollisionShape2D
	reading = true
	for i in get_tree().get_nodes_in_group("DialogBoxes"): #exit old
		i.exit()

	db = DB.instantiate()
	db.connect("dialog_finished", Callable(self, "on_dialog_finished"))
	w.dll.add_child(db)
	db.start_printing_flavor_text(text)

func on_dialog_finished():
	reading = false
