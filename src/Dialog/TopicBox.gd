extends MarginContainer

var sfx_prompt = load("res://assets/SFX/placeholder/snd_menu_prompt.ogg")
var sfx_move = load("res://assets/SFX/placeholder/snd_menu_move.ogg")
var sfx_select = load("res://assets/SFX/placeholder/snd_menu_select.ogg")

var dialog_box = load("res://src/Dialog/DialogBox.tscn")

const TOPIC_BUTTON = preload("res://src/Dialog/TopicButton.tscn")



onready var button_path = $Margin/HBox/ScrollContainer/GridContainer
onready var face_sprite = $Margin/HBox/Face/Sprite

onready var world = get_tree().get_root().get_node("World")
onready var pc = get_tree().get_root().get_node("World/Recruit")

func _ready():
	$Tween.interpolate_property(self, "margin_bottom", 0, 64, 0.8, Tween.EASE_IN_OUT, Tween.TRANS_SINE)
	$Tween.start()
	yield(get_tree().create_timer(0.8), "timeout")
	
	$Margin.visible = true
	$Tween.interpolate_property(face_sprite, "position", face_sprite.position, Vector2.ZERO, 0.1, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()
	for t in pc.topic_array:
		add_button(t)




func add_button(topic):
	var button = TOPIC_BUTTON.instance()
	button.text = topic
	button.connect("pressed", self, "on_button_pressed", [topic])
	button_path.add_child(button)
	
	if topic == pc.topic_array.front():
		button.grab_focus()
	
func on_button_pressed(topic):
	var db = world.get_node("UILayer/DialogBox")
	var dialog_json = db.current_dialog_json
	db.stop_printing()
	
	var new_db = dialog_box.instance()
	world.get_node("UILayer").add_child(new_db)
	new_db.start_printing(dialog_json, topic)
	
	self.queue_free()
