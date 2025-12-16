extends MarginContainer

var sfx_prompt = load("res://assets/SFX/placeholder/snd_menu_prompt.ogg")
var sfx_move = load("res://assets/SFX/placeholder/snd_menu_move.ogg")
var sfx_select = load("res://assets/SFX/placeholder/snd_menu_select.ogg")

var dialog_box = load("res://src/Dialog/DialogBox.tscn")

const TOPIC_BUTTON = preload("res://src/Dialog/TopicButton.tscn")



@onready var button_path = $Margin/HBox/ScrollContainer/GridContainer
@onready var face_sprite = $Margin/HBox/Face/Sprite2D

@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_tree().get_root().get_node("World/Juniper")

func _ready():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "offset_bottom", 64, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await tween.finished
	$Margin.visible = true
	var tween2 = get_tree().create_tween()
	tween2.tween_property(face_sprite, "position", Vector2.ZERO, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for t in pc.topic_array:
		add_button(t)



func add_button(topic):
	var button = TOPIC_BUTTON.instantiate()
	button.text = topic
	button.connect("pressed", Callable(self, "on_button_pressed").bind(topic))
	button_path.add_child(button)

	if topic == pc.topic_array.front():
		button.grab_focus()

func on_button_pressed(topic):
	var db = world.get_node("UILayer/UIGroup/DialogBox")
	var dialog_json = db.current_dialog_json
	db.exit()

	var new_db = dialog_box.instantiate()
	world.uig.add_child(new_db)
	new_db.start_printing(dialog_json, topic)

	self.queue_free()
