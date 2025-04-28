extends Control

var prompt_sound = load("res://assets/SFX/snd_menu_prompt.ogg")
var move_sound = load("res://assets/SFX/snd_menu_move.ogg")
var select_sound = load("res://assets/SFX/snd_menu_select.ogg")

var branch_id = ""

@onready var db = get_tree().get_root().get_node("World").get_node("UILayer/DialogBox")

func _on_Yes_pressed():
	$Audio.stream = select_sound
	$Audio.play()
	db.connected_npc.branch = "y" + branch_id
	db.connected_npc.dialog_step = 1
	db.connected_npc.progress_disabled = false
	db.connected_npc.progress_dialog(db.connected_npc.conversation)
	visible = false

func _on_No_pressed():
	$Audio.stream = select_sound
	$Audio.play()
	db.connected_npc.branch = "n" + branch_id
	db.connected_npc.dialog_step = 1
	db.connected_npc.progress_disabled = false
	db.connected_npc.progress_dialog(db.connected_npc.conversation)
	visible = false


func _on_Talk_pressed():
	$Audio.stream = select_sound
	$Audio.play()
	db.connected_npc.branch = "t" + branch_id
	db.connected_npc.dialog_step = 1
	db.connected_npc.progress_disabled = false
	db.connected_npc.progress_dialog(db.connected_npc.conversation)
	visible = false

func _on_Ask_pressed():
	$Audio.stream = select_sound
	$Audio.play()
	db.connected_npc.branch = "a" + branch_id
	db.connected_npc.dialog_step = 1
	db.connected_npc.progress_disabled = false
	db.connected_npc.progress_dialog(db.connected_npc.conversation)
	visible = false


func _on_button_focus_entered():
	$Audio.stream = move_sound
	$Audio.play()
