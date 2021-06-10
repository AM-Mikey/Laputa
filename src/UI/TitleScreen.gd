extends Control

const LEVELSELECT = preload("res://src/UI/LevelSelect.tscn")

onready var world = get_tree().get_root().get_node("World")
onready var player = get_tree().get_root().get_node("World/Recruit")
onready var hud = get_tree().get_root().get_node("World/UILayer/HUD")

var alpha_week: int

func _ready():
	var current_date = OS.get_date()
	var years_since = current_date["year"] - 2021
	var months_since = current_date["month"] - 3
	var days_since = current_date["day"] - 18
	
	if days_since < 0:
		
		var days_last_month
		match current_date["month"]:
			1, 2, 4, 6, 8, 9, 11: 
				days_last_month = 31
			3:
				days_last_month = 28
			5, 7, 10, 12:
				days_last_month = 30
			
		$CenterContainer/Label.text = "Alpha Build: " + str(months_since-1) + "m " + str(days_last_month + days_since) + "d"
	else:
		$CenterContainer/Label.text = "Alpha Build: " + str(months_since) + "m " + str(days_since) + "d"
	

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
	add_child(LEVELSELECT.instance())


func _on_Quit_pressed():
	pass # Replace with function body.
