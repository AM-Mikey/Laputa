extends Camera2D


func _ready():
	var title_previews = get_tree().get_nodes_in_group("TitlePreviews")
	for t in title_previews:
		global_position = t.global_position
		zoom = Vector2(t.zoom, t.zoom)
