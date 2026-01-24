extends Node2D

@export_file var actor_path

func _ready():
	if actor_path == null:
		printerr("ERROR: no actor chosen in ActorSpawnPreview")
		return
	var actor = load(actor_path).instantiate()
	$Sprite2D.texture = actor.get_node("Sprite2D").texture
	$Sprite2D.hframes = actor.get_node("Sprite2D").hframes
	$Sprite2D.vframes = actor.get_node("Sprite2D").vframes
	$Sprite2D.frame = actor.get_node("Sprite2D").frame
	$Sprite2D.position = actor.get_node("Sprite2D").position
