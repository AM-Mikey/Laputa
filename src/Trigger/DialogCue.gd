extends Trigger #TODO: OUTDATED

const DB = preload("res://src/Dialog/DialogBox.tscn")

@export (String, FILE, "*.json") var dialog_json: String
@export var conversation: String
@export var repeatable = false

@onready var world = get_tree().get_root().get_node("World")

func _ready():
	trigger_type = "dialog_cue"
	if not repeatable:
		add_to_group("LimitedTriggers") #TODO: consider doing this in editor

func _on_body_entered(_body):
	if not spent:
		expend_trigger()
		
		if world.has_node("UILayer/DialogBox"):
			world.get_node("UILayer/DialogBox").stop_printing()
			
		var dialog_box = DB.instantiate()
		get_tree().get_root().get_node("World/UILayer").add_child(dialog_box)
		dialog_box.start_printing(dialog_json, conversation)
		print("starting conversation")
