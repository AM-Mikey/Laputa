extends Control

onready var world = get_tree().get_root().get_node("World")
onready var player = get_tree().get_root().get_node("World/Recruit")
onready var hud = get_tree().get_root().get_node("World/UILayer/HUD")

func _on_New_pressed():
	visible = false
	queue_free()
	get_tree().reload_current_scene()


func _on_Load_pressed():
	visible = false
	player.disabled = false
	player.visible = true
	hud.visible = true
	world.load_player_data()
	world.load_level_data()


func _on_Options_pressed():
	pass # Replace with function body.


func _on_Level_pressed():
	pass # Replace with function body.


func _on_Quit_pressed():
	pass # Replace with function body.
