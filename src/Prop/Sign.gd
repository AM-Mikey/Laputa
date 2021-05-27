extends Area2D

var has_player_near = false
var reading = false
var active_player = null

var path = get_path()

export var display_name = ""
export var face: String = ""
export var expression: String = ""
export(String, MULTILINE) var text = ""
export var justify = "NFCenter"
export var voiced = false

onready var db = get_tree().get_root().get_node("World").get_node("UILayer/DialogBox")

signal display_text(path, display_name, face, expression, text, justify, voiced)
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
		emit_signal("display_text", display_name, path, face, expression, text, justify, voiced)
