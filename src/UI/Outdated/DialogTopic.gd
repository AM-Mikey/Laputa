extends Control

var prompt_sound = load("res://assets/SFX/snd_menu_prompt.ogg")
var move_sound = load("res://assets/SFX/snd_menu_move.ogg")
var select_sound = load("res://assets/SFX/snd_menu_select.ogg")

var font = load("res://src/UI/Cave-StoryFont.tres")

@onready var player = get_tree().get_root().get_node("World/Juniper")
@onready var db = get_tree().get_root().get_node("World").get_node("UILayer/DialogBox")
@onready var gc = $MarginContainer/ScrollContainer/GridContainer

func _ready():
	for t in player.topic_array:
		var button = Button.new()
		button.flat = true
		button.add_theme_font_override("font", font)
		button.text = t
		gc.add_child(button)
		
		button.connect("pressed", Callable(self, "_on_button_pressed").bind(t))

func _on_button_pressed(t_array):
	var button_name = String(t_array)
	$Audio.stream = select_sound
	$Audio.play()
	print(button_name)
	db.connected_npc.conversation = db.connected_npc.dialog[button_name]
	db.connected_npc.branch = ""
	db.connected_npc.dialog_step = 1
	db.connected_npc.progress_disabled = false
	db.connected_npc.progress_dialog(db.connected_npc.conversation)
	visible = false
