extends TileMap

const SPIKESLEFT = preload("res://src/Trigger/SpikesLeft.tscn")
const SPIKESRIGHT = preload("res://src/Trigger/SpikesRight.tscn")
const SPIKESUP = preload("res://src/Trigger/SpikesUp.tscn")
const SPIKESDOWN = preload("res://src/Trigger/SpikesDown.tscn")

@onready var triggers = get_parent().get_parent().get_node("Triggers")

func _ready():
	var spikes_left_tiles = get_used_cells_by_id(0)
	var spikes_right_tiles = get_used_cells_by_id(1)
	var spikes_up_tiles = get_used_cells_by_id(2)
	var spikes_down_tiles = get_used_cells_by_id(3)

	for s in spikes_left_tiles:
		var above = Vector2(s.x, s.y - 1)
		var below = Vector2(s.x, s.y + 1)
		if get_cell_source_id(0, above) == -1: #if this isn't the first cell, return
			var spikes_size = 1
			while get_cell_source_id(0, below) == 0:
				spikes_size +=1
				below.y += 1
			
			var spikes_left = SPIKESLEFT.instantiate()
			triggers.add_child(spikes_left)
			spikes_left.global_position = s * 16
			spikes_left.scale.y = spikes_size

	for s in spikes_right_tiles:
		var above = Vector2(s.x, s.y - 1)
		var below = Vector2(s.x, s.y + 1)
		if get_cell_source_id(0, above) == -1: #if this isn't the first cell, return
			var spikes_size = 1
			while get_cell_source_id(0, below) == 1:
				spikes_size +=1
				below.y += 1
		
			var spikes_right = SPIKESRIGHT.instantiate()
			triggers.add_child(spikes_right)
			spikes_right.global_position = s * 16
			spikes_right.scale.y = spikes_size

	for s in spikes_up_tiles:
		var left = Vector2(s.x -1, s.y)
		var right = Vector2(s.x +1, s.y)
		if get_cell_source_id(0, left) == -1: #if this isn't the first cell, return
			var spikes_size = 1
			while get_cell_source_id(0, right) == 2:
				spikes_size +=1
				right.x += 1
			
			var spikes_up = SPIKESUP.instantiate()
			triggers.add_child(spikes_up)
			spikes_up.global_position = s * 16
			spikes_up.scale.x = spikes_size

	for s in spikes_down_tiles:
		var left = Vector2(s.x -1, s.y)
		var right = Vector2(s.x +1, s.y)
		if get_cell_source_id(0, left) == -1: #if this isn't the first cell, return
			var spikes_size = 1
			while get_cell_source_id(0, right) == 3:
				spikes_size +=1
				right.x += 1
			
			var spikes_down = SPIKESDOWN.instantiate()
			triggers.add_child(spikes_down)
			spikes_down.global_position = s * 16
			spikes_down.scale.x = spikes_size

	visible = false
