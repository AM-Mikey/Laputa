extends Enemy

const A_STAR_PATH_LINE = preload("res://src/Utility/AStarPathLine.tscn")
const DEBUG_TARGET_TEXTURE = preload("res://assets/Editor/VisTrue.png")
const DEBUG_REST_TEXTURE = preload("res://assets/UI/FileSelect/XpIcon.png")


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


var leg_targets = {}
var leg_rest_positions = {}
var leg_positions = {}
var leg_max_distance = 64
var leg_step_distance = 32.0
var leg_speed = 15.0
#var leg_cooldown = 0.2
var leg_min_proximity = 4.0


func setup():
	reward = 5
	hp = 8
	speed = Vector2(60, 60)
	setup_a_star()
	change_state("chase")


func _on_physics_process(delta):
	for i in 8:
		var nearest_point = get_nearest_point_collision(%LegSectors.get_child(i))
		if nearest_point != Vector2.INF and leg_proximity_check(nearest_point, i):
			leg_targets[i] = nearest_point
		else:
			#remove leg TODO: tween
			leg_targets.erase(i)
			leg_rest_positions.erase(i)

	var enabled_rest_to_target_distances := {}
	for j in 8:
		if leg_targets.has(j):
			if !leg_rest_positions.has(j): #never set a rest pos yet
				enabled_rest_to_target_distances[j] = 99999.0
			else:
				var dist = leg_rest_positions[j].distance_to(leg_targets[j])
				if dist > leg_step_distance:
					enabled_rest_to_target_distances[j] = dist

	var active_leg := -1
	var active_leg_distance := 0.0
	for d in enabled_rest_to_target_distances:
		if enabled_rest_to_target_distances[d] > active_leg_distance: #NOTE: under this sceme, the octopus will always choose to start with leg 0. lower legs win ties in dist
			active_leg_distance = enabled_rest_to_target_distances[d] 
			active_leg = d
	
	if active_leg != -1: #do a step
		#print("octopus_step")
		leg_rest_positions[active_leg] = leg_targets[active_leg]
		if !leg_positions.has(active_leg): #first time, just put it on the target
			leg_positions[active_leg] = leg_targets[active_leg]
	
	for k in 8:
		if leg_positions.has(k) && leg_rest_positions.has(k):
			leg_positions[k] = leg_positions[k].lerp(leg_rest_positions[k], delta * leg_speed) #otherwise lerp to the rest position
	
	if debug: set_leg_debug_visuals()
	update_legs(delta)



### A STAR ###

func setup_a_star():
	for l in w.front.get_children():
		if l.is_in_group("AStarPathLines"):
			l.queue_free()
	a_star_line = A_STAR_PATH_LINE.instantiate()
	a_star_grid = AStarGrid2D.new()

	var tile_map = w.current_level.get_node("TileMap")
	var used_region = Rect2(Vector2i(w.current_level.get_node("LevelLimiter").global_position / 16.0), Vector2i(w.current_level.get_node("LevelLimiter").size / 16.0))

	a_star_grid.region = used_region
	a_star_grid.cell_size = Vector2(16, 16)
	a_star_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	a_star_grid.offset = Vector2(8, 8)
	a_star_grid.update()

	#use this to destinguish which points are solid, based on collision
	var tiles_with_collision = []
	var source = tile_map.get_child(0).tile_set.get_source(0)
	for column in source.texture_region_size.x:
		for row in source.texture_region_size.y:
			if source.get_tile_at_coords(Vector2i(column, row)) != Vector2i(-1, -1):
				var tile_data = source.get_tile_data(Vector2i(column, row), 0)
				if tile_data.get_collision_polygons_count(0) != 0: #there is collision on layer 0
					tiles_with_collision.append(Vector2i(column, row))
	for tile_map_layer: TileMapLayer in tile_map.get_children():
		for cell in tile_map_layer.get_used_cells():
			var tile = tile_map_layer.get_cell_atlas_coords(cell)
			if tiles_with_collision.has(tile):

				#var sprite = Sprite2D.new()
				#sprite.texture = load("res://assets/Icon/EnemyIcon.png")
				#sprite.position = (cell * 16) + Vector2i(8,8)
				#sprite.z_index = 999
				#w.add_child(sprite)

				a_star_grid.set_point_solid(cell, true)
				a_star_grid.update()

func find_path():
	if !pc: return
	var self_node_position = Vector2i((global_position + Vector2(-8, -8)).snapped(Vector2(16, 16)) / 16.0)
	var pc_node_position = Vector2i((pc.global_position + Vector2(-8, -16)).snapped(Vector2(16, 16)) / 16.0) #an extra (0,-8) to get center mass on juniper
	path = a_star_grid.get_point_path(self_node_position, pc_node_position)
	a_star_line.points = path
	current_point = 1
	#if debug: #warning this orphans the node
		#w.front.add_child(a_star_line)


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
		velocity = calc_velocity(move_dir, false)
		move_and_slide()



### HELPERS ###

func get_nearest_point_collision(sector: CollisionShape2D) -> Vector2:
	var closest_point := Vector2.ZERO
	var closest_distance := INF
	var space := get_world_2d().direct_space_state
	var max_scale = leg_max_distance / 128.0 #NOTE: sector shapes must have distance of 128 for this to work
	sector.scale = Vector2.ZERO
	while closest_distance == INF and sector.scale.x < max_scale:
		var params := PhysicsShapeQueryParameters2D.new()
		params.shape = sector.shape
		params.transform = sector.global_transform
		params.collide_with_areas = false
		params.collide_with_bodies = true
		params.collision_mask = 8 #just world
		var points: Array[Vector2] = []

		for l in w.current_level.get_node("TileMap").get_children(): #for all layers
			points.append_array(space.collide_shape(params, 32))

		for p in points:
			var distance := p.distance_squared_to(global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_point = p

		sector.scale += Vector2(0.01, 0.01) #if this lags increase the scale by more

	if closest_distance == INF: # If nothing intersected
		return Vector2.INF
	return closest_point

func leg_proximity_check(point, leg_index):
	for t in leg_targets:
		if t != leg_index: #dont check proximity to itself
			if leg_targets[t].distance_to(point) < leg_min_proximity:
				return false
	return true


func set_leg_debug_visuals():
	for ct in %DebugTargets.get_children():
		ct.queue_free()
	for cr in %DebugRests.get_children():
		cr.queue_free()
	for t in leg_targets:
		var debug_target = Sprite2D.new()
		debug_target.z_index = 999
		debug_target.centered = true
		debug_target.self_modulate = Color("ffffffc8")
		debug_target.texture = DEBUG_TARGET_TEXTURE
		debug_target.global_position = to_local(leg_targets[t])
		%DebugTargets.add_child(debug_target)
	for r in leg_rest_positions:
		var debug_rest = Sprite2D.new()
		debug_rest.z_index = 999
		debug_rest.centered = true
		debug_rest.self_modulate = Color("ffffffc8")
		debug_rest.texture = DEBUG_REST_TEXTURE
		debug_rest.global_position = to_local(leg_rest_positions[r])
		%DebugTargets.add_child(debug_rest)


func update_legs(delta):
	for i in 8:
		if leg_positions.has(i):
			if leg_rest_positions.has(i):
				%LegLines.get_child(i).set_point_position(1, to_local(leg_positions[i]))
			else:
				var lerp_to = to_global(get_leg_trailing_position(%LegLines.get_child(i).get_point_position(0)))
				leg_positions[i] = leg_positions[i].lerp(lerp_to, delta * leg_speed) #lerp to line point 0
				#print(leg_positions[i])
				%LegLines.get_child(i).set_point_position(1, to_local(leg_positions[i]))
				
			#if %LegLines.points == [Vector2.ZERO, Vector2.ZERO]:
				#%LegLines.get_child(i).visible = false
			#else:
				#%LegLines.get_child(i).visible = true

func get_leg_trailing_position(leg_origin) -> Vector2:
	var out: Vector2
	var opposite_movement_angle = move_dir.angle() + PI
	var move_by = Vector2(leg_max_distance, 0).rotated(opposite_movement_angle)
	out = leg_origin + move_by
	#print("s")
	return out

### SIGNALS ###

func _on_PlayerDetector_body_entered(body):
	target = body.owner
	if state == "idle":
		change_state("popin")

func _on_PlayerDetector_body_exited(_body):
	target = null



### old code save for spider or walker etc
#func _on_physics_process(delta):
	#var nearest_ne = get_nearest_point_collision($LegSectorNE)
	#if nearest_ne != Vector2.INF:
		#ne_leg_target = nearest_ne
#
	#var nearest_nw = get_nearest_point_collision($LegSectorNW)
	#if nearest_nw != Vector2.INF:
		#nw_leg_target = nearest_nw
#
#
	#if north_legs_enabled:
		#var can_west_step = false
		#var can_east_step = false
#
		#if nw_leg_target != Vector2.INF && nw_leg_rest_position.distance_to(nw_leg_target) > leg_step_distance:
			#can_west_step = true
		#if ne_leg_target != Vector2.INF && ne_leg_rest_position.distance_to(ne_leg_target) > leg_step_distance:
			#can_east_step = true
#
		#if can_west_step and !can_east_step:
			#print("west_step")
			#nw_leg_rest_position = nw_leg_target
		#elif can_east_step and !can_west_step:
			#print("east_step")
			#ne_leg_rest_position = ne_leg_target
		#elif can_west_step and can_east_step:
			#if nw_leg_rest_position.distance_to(nw_leg_target) > ne_leg_rest_position.distance_to(ne_leg_target):
				#print("west_step")
				#nw_leg_rest_position = nw_leg_target
			#else:
				#print("east_step")
				#ne_leg_rest_position = ne_leg_target
#
#
		#north_legs_enabled = false
		#$NorthLegCooldown.start(leg_cooldown)
#
	#if ne_leg_position == Vector2.INF:
		#ne_leg_position = ne_leg_target
	#else:
		#ne_leg_position = ne_leg_position.lerp(ne_leg_rest_position, delta * leg_speed)
#
	#if nw_leg_position == Vector2.INF:
		#nw_leg_position = nw_leg_target
	#else:
		#nw_leg_position = nw_leg_position.lerp(nw_leg_rest_position, delta * leg_speed)
#
	#$LegRestNE.global_position = ne_leg_rest_position
	#$LegRestNW.global_position = nw_leg_rest_position
	#update_legs()
