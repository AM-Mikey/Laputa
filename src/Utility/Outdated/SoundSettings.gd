extends Control

onready var master_label = $MarginContainer/ScrollContainer/VBoxContainer/MasterLabel
onready var music_label = $MarginContainer/ScrollContainer/VBoxContainer/MusicLabel
onready var sfx_label = $MarginContainer/ScrollContainer/VBoxContainer/SFXLabel

func _on_MasterSlider_value_changed(value):
	var db = percent_to_db(value)
	var volume = AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),db)
	if value == 0:
		master_label.text = "Master Volume: Muted"
	else:
		master_label.text = "Master Volume: " + str(value) + "0 '/."

func _on_MusicSlider_value_changed(value):
	var db = percent_to_db(value)
	var volume = AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),db)
	if value == 0:
		music_label.text = "Music Volume: Muted"
	else:
		music_label.text = "Music Volume: " + str(value) + "0 '/."

func _on_SFXSlider_value_changed(value):
	var db = percent_to_db(value)
	var volume = AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"),db)
	if value == 0:
		sfx_label.text = "SFX Volume: Muted"
	else:
		sfx_label.text = "SFX Volume: " + str(value) + "0 '/."

func percent_to_db(value) -> float:
	var db: float
	
	if value == 0:
		db = -80
	elif value == 1:
		db = -20
	elif value == 2:
		db = -13.9794
	elif value == 3:
		db = -10.4576
	elif value == 4:
		db = -7.9588
	elif value == 5:
		db = -6.0206
	elif value == 6:
		db = -4.4370 
	elif value == 7:
		db = -3.0980
	elif value == 8:
		db = -1.9382 
	elif value == 9:
		db = -0.9151
	elif value == 10:
		db = 0
	elif value == 11:
		db = 0.8279 
	elif value == 12:
		db = 1.5836 
	elif value == 13:
		db = 2.2789
	elif value == 14:
		db = 2.9226
	elif value == 15:
		db = 3.5218
	elif value == 16:
		db = 4.0824
	elif value == 17:
		db = 4.6090
	elif value == 18:
		db = 5.1055
	elif value == 19:
		db = 5.5751 
	elif value == 20:
		db = 6.0206
	else:
		db = 0
	
	return db
