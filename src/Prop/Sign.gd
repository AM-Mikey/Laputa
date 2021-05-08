extends Area2D

var has_player_near = false
var reading = false
var active_player = null



export var face: String = "No Face"
export var expression: String = "No Expression"
export var text: String = "ERROR: NO DIALOG"
export var justify = "NoFace"
export var voiced = false

onready var db = get_tree().get_root().get_node("World").get_node("UILayer/DialogBox")

signal display_text(face, expression, text, justify, voiced)
signal stop_text()

func _ready():
	connect("display_text", db, "_on_display_text")
	connect("stop_text", db, "_on_stop_text")

func _on_Sign_body_entered(body):
	has_player_near = true
	active_player = body

func _on_ExitDetector_body_exited(body):
	has_player_near = false
	emit_signal("stop_text")
	if reading == true:
		reading = false

func _input(event):
	if event.is_action_pressed("inspect") and has_player_near == true and reading == false:
		reading = true
		emit_signal("display_text", face, expression, text, justify, voiced)
