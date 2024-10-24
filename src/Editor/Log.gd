extends MarginContainer

const LOG_MESSAGE = preload("res://src/Editor/LogMessage.tscn")

var max_message_count := 3

@onready var w = get_tree().get_root().get_node("World")
@onready var editor = get_parent().get_parent()

func _ready():
	for c in $VBox.get_children():
		c.queue_free()

func lprint(message: String):
	var log_message = LOG_MESSAGE.instantiate()
	log_message.text = message
	$VBox.add_child(log_message)

func _process(delta):
	if $VBox.get_child_count() > max_message_count:
		$VBox.get_child(-1).queue_free()
