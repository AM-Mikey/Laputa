extends Node

func add_cutscene(path: String) -> Cutscene:
	var new_cutscene_node
	if path.ends_with(".tscn"):
		new_cutscene_node = load(path).instantiate()
	elif path.ends_with(".gd"):
		new_cutscene_node = Node.new()
		new_cutscene_node.set_script(load(path))
	else:
		push_error("Invalid file type")
		return
	add_child(new_cutscene_node)
	return new_cutscene_node

func delete_cutscene(path: String) -> bool:
	if path.ends_with(".tscn"):
		for child in get_children():
			if child.scene_file_path == path:
				child.queue_free()
				return true
	elif path.ends_with(".gd"):
		for child in get_children():
			var child_script = child.get_script()
			if child_script.resource_path == path:
				child.queue_free()
				return true
	else:
		push_error("Invalid file type")
	return false
