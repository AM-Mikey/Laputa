extends Area2D

const DB = preload("res://src/Dialog/DialogBox.tscn")

var has_player_near = false
var reading = false
var active_player = null

var path = get_path() #what is this doing anyway?


#we're not actually passing any of these right now other than text
export var display_name = ""
export var face: String = ""
export var expression: String = ""
export(String, MULTILINE) var text = ""
export var justify = "NFCenter"
export var voiced = false

var db

#signal display_text(path, display_name, face, expression, text, justify, voiced)
#signal stop_text()

onready var world = get_tree().get_root().get_node("World")

func _on_Sign_body_entered(body):
	has_player_near = true
	active_player = body

func _on_ExitDetector_body_exited(_body):
	has_player_near = false
	emit_signal("stop_text")
	if reading:
		db.queue_free()
		reading = false

func _input(event):
	if event.is_action_pressed("inspect") and has_player_near == true and active_player.disabled == false:
		if not reading:
			reading = true
			yield(get_tree().create_timer(.0001), "timeout")
			
			if world.has_node("UILayer/DialogBox"): #clear old dialog box if there is one
				world.get_node("UILayer/DialogBox").stop_printing()
			
			db = DB.instance()
			get_tree().get_root().get_node("World/UILayer").add_child(db)
			db.text = text
			db.print_sign()
		else:
			db.queue_free()
			reading = false
