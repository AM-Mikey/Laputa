extends Control

const LEVELSELECT = preload("res://src/UI/LevelSelect.tscn")
const SETTINGS = preload("res://src/UI/Settings.tscn")

onready var world = get_tree().get_root().get_node("World")
onready var player = get_tree().get_root().get_node("World/Recruit")
onready var hud = get_tree().get_root().get_node("World/UILayer/HUD")

var alpha_week: int

func _ready():
	
												#VERSION STUFF
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
			
		$CenterContainer/Label.text = "Alpha Version: " + str(months_since-1) + "m " + str(days_last_month + days_since) + "d"
	else:
		$CenterContainer/Label.text = "Alpha Version: " + str(months_since) + "m " + str(days_since) + "d"
	
										#LOAD BUTTON STUFF
	var file = File.new()
	if file.file_exists(world.save_path):
		var file_read = file.open(world.save_path, File.READ)
		if file_read == OK:
			var data = file.get_var()
			file.close()
			if data["player_data"].size() == 0:
				$MarginContainer/VBoxContainer/Load.queue_free()
			
		else: $MarginContainer/VBoxContainer/Load.queue_free()
	else: $MarginContainer/VBoxContainer/Load.queue_free()
	

func _on_New_pressed():
	visible = false
	queue_free()
	
	world._on_level_change(world.starting_level, 0, "LevelSelect", "res://assets/Music/XXXX.ogg")
	world.get_node("Recruit").visible = true
	world.get_node("Recruit").disabled = false
	world.get_node("UILayer/HUD").visible = true
	
	var spawn_points = get_tree().get_nodes_in_group("SpawnPoints")
	for s in spawn_points:
		world.get_node("Recruit").position = s.global_position
	


func _on_Load_pressed():
	visible = false
	player.disabled = false
	player.visible = true
	hud.visible = true
	world.load_player_data()
	world.load_level_data()


func _on_Options_pressed():
	add_child(SETTINGS.instance())


func _on_Level_pressed():
	add_child(LEVELSELECT.instance())


func _on_Quit_pressed():
	get_tree().quit()
