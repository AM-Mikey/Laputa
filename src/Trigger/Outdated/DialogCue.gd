extends Trigger #TODO: OUTDATED

const DB = preload("res://src/Dialog/DialogBox.tscn")

#@export (String, FILE, "*.json") var dialog_json: String
@export var conversation: String
@export var repeatable = false


func _ready():
	trigger_type = "dialog_cue"
	if not repeatable:
		add_to_group("LimitedTriggers") #TODO: consider doing this in editor

func _on_body_entered(_body):
	if not spent:
		expend_trigger()

		if f.db():
			f.db().stop_printing()

		var dialog_box = DB.instantiate()
		w.dll.add_child(dialog_box)
		dialog_box.start_printing(dialog_json, conversation)
		print("starting conversation")
