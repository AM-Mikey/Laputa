extends MarginContainer

const LOAD_COLOR = Color(1.3, 1.3, 1.3, 1.0)
const COPY_COLOR = Color(0.0, 1.0, 0.0, 1.0)
const DELETE_COLOR = Color(1.0, 0.0, 0.0, 1.0)

var save_file_path: String
var data: Dictionary
var slot_index: int

var level_path: String
var gun_names: Array
var unix_time: int
var uptime: int

var file_select: Node
@onready var w = get_tree().get_root().get_node("World")

func _ready():
	display_data()

func display_data():
	#save_file = FileAccess.open(save_file_path, FileAccess.READ)
	data = SaveSystem.read_from_file(save_file_path)
	level_path = data["player_data"]["current_level"]
	%SlotLabel.text = "Save %s" % slot_index
	%LevelLabel.text = level_path.get_file().trim_suffix(".tscn").capitalize()
	%HpLabel.text = "%s / %s" % [data["player_data"]["hp"], data["player_data"]["max_hp"]]
	%XpLabel.text = str(data["player_data"]["money"])
	gun_names = data["player_data"]["gun_data"].keys()
	unix_time = data["other_data"]["unix_time"]
	uptime = data["other_data"]["uptime"]

	for c in %Guns.get_children():
		c.visible = false

	for i in range(gun_names.size()):
		var gun_name = gun_names[i]
		var gun_node = get_node_or_null("%Gun" + str(i))
		if gun_node:
			gun_node.texture = load("res://assets/Gun/%sIcon.png" % gun_name)
			gun_node.visible = true


	var time_zone: Dictionary = Time.get_time_zone_from_system()
	var bias_seconds: int = time_zone["bias"] * 60
	var datetime = Time.get_datetime_dict_from_unix_time(unix_time + bias_seconds)
	%DateLabel.text = "%s/%s/%s" % [datetime["month"], datetime["day"], datetime["year"]]
	var hour: int = datetime["hour"]
	var period: String = "AM" if hour < 12 else "PM"
	hour = hour % 12
	if hour == 0:
		hour = 12
	%TimeLabel.text = "%02d:%02d:%02d %s" % [hour, datetime["minute"], datetime["second"], period]

	var uptime_total_seconds: = int(uptime / 1000.0)
	var uptime_hours: int = uptime_total_seconds / 3600.0
	var uptime_minutes: int = (uptime_total_seconds % 3600) / 60.0
	var uptime_seconds: int = uptime_total_seconds % 60
	%UptimeLabel.text = "%02d:%02d:%02d" % [uptime_hours, uptime_minutes, uptime_seconds]


func _on_Button_pressed():
	match file_select.mode:
		file_select.Modes.LOAD:
			SaveSystem.current_slot = slot_index
			SaveSystem.read_player_data_from_save()
			SaveSystem.read_level_data_from_save(w.current_level)
			SaveSystem.read_dialog_data_from_save(w.current_level)
			SaveSystem.copy_level_and_dialog_data_from_save_to_temp()
			SaveSystem.read_mission_data_from_save()
			SaveSystem.read_other_data_from_save()
			file_select.exit()
		file_select.Modes.COPY:
			var new_slot = SaveSystem.file_select_copy_save(slot_index)
			file_select.mode = file_select.Modes.LOAD
			file_select.reload_previews(new_slot)
			#copy file to next available slot
			#change mode to load
		file_select.Modes.DELETE:
			file_select.prompt_delete(slot_index)
			#prompt popup, grab_focus on no
			#delete file on yes pressed
			#renumber remaining files
			#change pointer file
			#change mode to load


func _on_Button_focus_entered():
	match file_select.mode:
		file_select.Modes.LOAD:
			$Panel.modulate = LOAD_COLOR
		file_select.Modes.COPY:
			$Panel.modulate = COPY_COLOR
		file_select.Modes.DELETE:
			$Panel.modulate = DELETE_COLOR


func _on_Button_focus_exited():
	$Panel.modulate = Color.WHITE
