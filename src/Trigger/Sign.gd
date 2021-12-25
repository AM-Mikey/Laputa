extends Trigger

const DB = preload("res://src/Dialog/DialogBox.tscn")

var reading = false

#we're not actually passing any of these right now other than text
export var display_name = ""
export var face: String = ""
export var expression: String = ""
export(String, MULTILINE) var text = ""
export var justify = "NFCenter"
export var voiced = false

var db

onready var world = get_tree().get_root().get_node("World")

func _on_Sign_body_entered(body):
	active_pc = body

func _on_ExitDetector_body_exited(_body):
	active_pc = null
	emit_signal("stop_text")
	if reading:
		db.queue_free()
		reading = false

func _input(event):
	if not reading:
		if event.is_action_pressed("inspect") and active_pc != null:
			if not active_pc.disabled:
				reading = true
				
				if world.has_node("UILayer/DialogBox"): #clear old dialog box if there is one
					world.get_node("UILayer/DialogBox").stop_printing()
				
				db = DB.instance()
				get_tree().get_root().get_node("World/UILayer").add_child(db)
				db.text = text
				db.print_sign()
	else:
		db.queue_free()
		reading = false
