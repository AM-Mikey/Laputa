extends Area2D

const DB = preload("res://src/Dialog/DialogBox.tscn")

export (String, FILE, "*.json") var dialog_json: String
export var conversation: String

onready var world = get_tree().get_root().get_node("World")


func _on_DialogCue_body_entered(body):
	yield(get_tree().create_timer(.0001), "timeout") #why?

	if world.has_node("UILayer/DialogBox"): #clear old dialog box if there is one
		world.get_node("UILayer/DialogBox").stop_printing()
		
	var dialog_box = DB.instance()
	get_tree().get_root().get_node("World/UILayer").add_child(dialog_box)
	dialog_box.start_printing(dialog_json, conversation)
	print("starting conversation")
	queue_free()
