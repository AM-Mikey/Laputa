extends Enemy

const A_STAR_PATH_LINE = preload("res://src/Utility/AStarPathLine.tscn")

var target

var move_dir = Vector2.ZERO
#var look_dir = Vector2.LEFT

var popin_time = 0.6
var popout_time = 0.6

var path: PackedVector2Array
var current_point := 0
var point_tolerance = 1
var a_star_line
var a_star_grid


func setup():
	reward = 5
	hp = 8
	speed = Vector2(100, 100)
	setup_a_star()
	change_state("chase")
#
#func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("debug_level_up"):
		#setup_a_star()

func setup_a_star():
	for l in w.front.get_children():
		if l.is_in_group("AStarPathLines"):
			l.queue_free()
	a_star_line = A_STAR_PATH_LINE.instantiate()
	a_star_grid = AStarGrid2D.new()
	
	var tile_map = w.current_level.get_node("TileMap")
	a_star_grid.region = tile_map.get_used_rect()
	a_star_grid.cell_size = Vector2(16, 16)
	a_star_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES  
	a_star_grid.offset = Vector2(8, 8)
	a_star_grid.update()
	
	#use this to destinguish which points are solid, based on collision
	var tiles_with_collision = []
	var source = tile_map.tile_set.get_source(0)
	for column in source.texture_region_size.x:
		for row in source.texture_region_size.y:
			if source.get_tile_at_coords(Vector2i(column, row)) != Vector2i(-1, -1):
				var tile_data = source.get_tile_data(Vector2i(column, row), 0)
				if tile_data.get_collision_polygons_count(0) != 0: #there is collision on layer 0
					tiles_with_collision.append(Vector2i(column, row))
	for layer in 4:
		for cell in tile_map.get_used_cells(layer): 
			var tile = tile_map.get_cell_atlas_coords(layer, cell)
			if tiles_with_collision.has(tile):
				#var sprite = Sprite2D.new()
				#sprite.texture = load("res://assets/Icon/EnemyIcon.png")
				#sprite.position = (cell * 16) + Vector2i(8,8)
				#sprite.z_index = 999
				#w.add_child(sprite)
				a_star_grid.set_point_solid(cell, true)
				a_star_grid.update()

func find_path():
	var self_node_position = Vector2i((global_position + Vector2(-8, -8)).snapped(Vector2(16, 16)) / 16.0)
	var pc_node_position = Vector2i((pc.global_position + Vector2(-8, -16)).snapped(Vector2(16, 16)) / 16.0) #an extra (0,-8) to get center mass on juniper
	path = a_star_grid.get_point_path(self_node_position, pc_node_position)
	a_star_line.points = path
	current_point = 1
	if debug: #warning this orphans the node
		w.front.add_child(a_star_line)


### STATES ###

func do_idle():
	pass

func do_popin():
	$StateTimer.start(popin_time)
	await $StateTimer.is_stopped()
	pass
	#change_state("chase")

func do_popout():
	pass

func do_chase(): #goes to point 1 first btw
	find_path()
	if path.size() < 2: return
	if abs(global_position.x - path[current_point].x) < point_tolerance \
	and abs(global_position.y - path[current_point].y) < point_tolerance: 
		if current_point + 1 < path.size():
			current_point += 1
		else: #last point
			return
	else:
		move_dir = (path[current_point] - global_position).normalized()
		velocity = calc_velocity(velocity, move_dir, speed, false)
		move_and_slide()

### SIGNALS ###

func _on_PlayerDetector_body_entered(body):
	target = body.owner
	if state == "idle":
		change_state("popin")

func _on_PlayerDetector_body_exited(_body):
	target = null
