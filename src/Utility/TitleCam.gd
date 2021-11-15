extends Camera2D


func _ready():
	var spawn_points = get_tree().get_nodes_in_group("SpawnPoints")
	for s in spawn_points:
		global_position = s.global_position
