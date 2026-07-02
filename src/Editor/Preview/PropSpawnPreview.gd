extends Node2D

@export_file var prop_path

func _ready():
	if prop_path == null:
		printerr("ERROR: no actor chosen in PropSpawnPreview")
		return
	var prop = load(prop_path).instantiate()
	prop.queue_free()
	$Sprite2D.texture = prop.get_node("Sprite2D").texture
	$Sprite2D.hframes = prop.get_node("Sprite2D").hframes
	$Sprite2D.vframes = prop.get_node("Sprite2D").vframes
	$Sprite2D.frame = prop.get_node("Sprite2D").frame
	$Sprite2D.position = prop.get_node("Sprite2D").position
