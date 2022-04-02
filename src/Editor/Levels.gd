extends MarginContainer


onready var w = get_tree().get_root().get_node("World")


### SIGNALS ###

func _on_Save_pressed():
	$Save.popup()

func _on_Save_confirmed():
	var path = $Save.current_path.get_basename() + ".tscn"
	var level = w.current_level
	
	if path.is_valid_filename():
		var packed_scene = PackedScene.new()
		packed_scene.pack(level)
		ResourceSaver.save(path, packed_scene)
		print("Saved Level to: " + path)
