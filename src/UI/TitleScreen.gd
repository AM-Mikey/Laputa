extends Control

const LEVELSELECT = preload("res://src/UI/LevelSelect.tscn")
const SETTINGS = preload("res://src/UI/Settings.tscn")
const KEYCONFIG = preload("res://src/UI/KeyConfig.tscn")

onready var world = get_tree().get_root().get_node("World")
onready var player = get_tree().get_root().get_node("World/Recruit")
onready var hud = get_tree().get_root().get_node("World/UILayer/HUD")

var alpha_week: int

func _ready():
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()

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
			
		$MarginContainer/VersionLabel.text = "Alpha Version: " + str(months_since-1) + "m " + str(days_last_month + days_since) + "d"
	else:
		$MarginContainer/VersionLabel.text = "Alpha Version: " + str(months_since) + "m " + str(days_since) + "d"
	
										#LOAD BUTTON STUFF
	var file = File.new()
	if file.file_exists(world.save_path):
		var file_read = file.open(world.save_path, File.READ)
		if file_read == OK:
			var data = file.get_var()
			file.close()
			if data != null:
				if data.has("player_data"):
					if data["player_data"].size() == 0:
						$MarginContainer/CenterContainer/VBoxContainer/Load.queue_free()
				else:$MarginContainer/CenterContainer/VBoxContainer/Load.queue_free()
			else:$MarginContainer/CenterContainer/VBoxContainer/Load.queue_free()
		else: $MarginContainer/CenterContainer/VBoxContainer/Load.queue_free()
	

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
	world.load_player_data_from_save()
	world.load_level_data_from_save()
	world.copy_level_data_to_temp()


func _on_Options_pressed():
	get_parent().add_child(SETTINGS.instance())


func _on_Level_pressed():
	get_parent().add_child(LEVELSELECT.instance())


func _on_Quit_pressed():
	get_tree().quit()


func _on_KeyConfig_pressed():
	get_parent().add_child(KEYCONFIG.instance())
	
func _on_viewport_size_changed():
	$MarginContainer.rect_size = get_tree().get_root().size / world.resolution_scale
