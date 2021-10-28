extends Area2D

const DB = preload("res://src/Dialog/DialogBox.tscn")

var has_player_near = false
var reading = false
var active_player = null


export(String, MULTILINE) var text = ""

var db

onready var world = get_tree().get_root().get_node("World")

func _on_Sign_body_entered(body):
	has_player_near = true
	active_player = body

func _on_ExitDetector_body_exited(_body):
	has_player_near = false
	if reading:
		db.stop_printing()


func _input(event):
	if not reading:
		if event.is_action_pressed("inspect") and has_player_near and not active_player.disabled:
			reading = true
			yield(get_tree().create_timer(.0001), "timeout") #why?
			
			if world.has_node("UILayer/DialogBox"): #clear old dialog box if there is one
				world.get_node("UILayer/DialogBox").stop_printing()
			
			db = DB.instance()
			get_tree().get_root().get_node("World/UILayer").add_child(db)
			db.connect("dialog_finished", self, "on_dialog_finished")
			db.text = text
			db.print_flavor_text()


func on_dialog_finished():
	reading = false
