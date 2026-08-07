extends Enemy

const A_STAR_PATH_LINE = preload("res://src/Utility/AStarPathLine.tscn")
const DEBUG_TARGET_TEXTURE = preload("res://assets/Editor/VisTrue.png")
const DEBUG_REST_TEXTURE = preload("res://assets/UI/FileSelect/XpIcon.png")


var target

var move_dir = Vector2.ZERO

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

@export_group("Leg IK")
@export var leg_segment_count: int = 16 ## number of IK segments per tentacle - change this to grow/shrink the chains
@export var leg_ik_iterations: int = 10 ## FABRIK solver iterations run per leg per frame
@export var leg_chain_follow_speed: float = 18.0 ## how fast the drawn chain eases toward its solved/curled pose

@export_group("Leg Idle Curl")
@export var leg_curl_amount: float = .65 ## radians the chain bends per segment while idle (curls the tentacle up)
@export var leg_curl_wiggle_amount: float = 0.18 ## radians of extra sinusoidal wiggle applied while idle
@export var leg_curl_speed: float = 2.2 ## speed of the idle wiggle animation

var leg_segment_length: float = 8.0 #recomputed in setup() as leg_max_distance / leg_segment_count so the IK chain still reaches leg_max_distance
var leg_chain_points = {} #leg_index -> PackedVector2Array of GLOBAL joint positions, hip [0] ... tip [leg_segment_count]
var leg_hip_positions = {} #leg_index -> local hip anchor, cached from each Line2D's authored point 0

var base_speed := Vector2(40.0, 40.0)
var grab_speed := Vector2(10.0, 10.0)
var grab_decay_rate := 5.0
var grab_velocity := Vector2.ZERO

func setup():
	reward = 5
	hp = 8
	speed = base_speed
	setup_a_star()
	leg_segment_length = leg_max_distance / float(leg_segment_count)
	init_leg_chains()
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

		#speed boost
		var move_angle = move_dir.angle()
		var angle_to_leg = self.get_angle_to(leg_rest_positions[active_leg])
		var angle_dif = angle_difference(move_angle, angle_to_leg)
		var alignment_factor = cos(angle_dif)
		var speed_multiplier = max(0.0, alignment_factor)
		grab_velocity += speed_multiplier * grab_speed.rotated(move_angle)

	grab_velocity = grab_velocity.move_toward(Vector2.ZERO, grab_decay_rate * delta)

	for k in 8:
		if leg_positions.has(k) && leg_rest_positions.has(k):
			leg_positions[k] = leg_positions[k].lerp(leg_rest_positions[k], delta * leg_speed) #otherwise lerp to the rest position


	#print(leg_targets.size())
	#if leg_targets.size() == 0:
		#speed = base_speed / 4.0
	#elif leg_targets.size() < 4:
		#speed = base_speed / leg_targets.size()
	#else:
		#speed = base_speed
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
		velocity += grab_velocity
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


### LEG IK / CURL ###

func init_leg_chains():
	for i in 8:
		var line: Line2D = %LegLines.get_child(i)
		var hip_local: Vector2 = line.get_point_position(0) if line.get_point_count() > 0 else Vector2.ZERO
		leg_hip_positions[i] = hip_local
		leg_chain_points[i] = make_flat_chain(to_global(hip_local))

		#round joints/caps so a multi-segment chain reads as a smooth tentacle instead of a jagged polyline
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND

		#taper the tentacle: thick where it meets the body, thin at the tip
		var taper := Curve.new()
		taper.add_point(Vector2(0.0, 1.0))
		taper.add_point(Vector2(1.0, 0.35))
		line.width_curve = taper

func make_flat_chain(hip_global: Vector2) -> PackedVector2Array:
	var chain := PackedVector2Array()
	chain.resize(leg_segment_count + 1)
	for p in chain.size():
		chain[p] = hip_global
	return chain

func update_legs(delta):
	var t := Time.get_ticks_msec() / 1000.0
	for i in 8:
		var line: Line2D = %LegLines.get_child(i)
		var hip_local: Vector2 = leg_hip_positions.get(i, line.get_point_position(0))
		var hip_global: Vector2 = to_global(hip_local)

		if !leg_chain_points.has(i) or leg_chain_points[i].size() != leg_segment_count + 1:
			leg_chain_points[i] = make_flat_chain(hip_global) #first frame for this leg, or segment_count changed live
		var current_chain: PackedVector2Array = leg_chain_points[i]

		var is_grounded := leg_rest_positions.has(i) and leg_positions.has(i)
		var desired_chain: PackedVector2Array
		if is_grounded: #reach for the planted foot target with a bending IK chain
			desired_chain = solve_leg_ik(current_chain, hip_global, leg_positions[i], leg_segment_length, leg_ik_iterations)
		else: #not currently targeting anything - curl the tentacle in near the body instead
			desired_chain = get_curl_chain(hip_global, i, t)
			leg_positions[i] = desired_chain[desired_chain.size() - 1] #keep the last-known tip in sync so re-grounding eases in smoothly

		var follow_t: float = clamp(delta * leg_chain_follow_speed, 0.0, 1.0)
		var new_chain := PackedVector2Array()
		new_chain.resize(current_chain.size())
		new_chain[0] = hip_global #the hip is rigidly attached to the body, it never lags
		for p in range(1, current_chain.size()):
			new_chain[p] = current_chain[p].lerp(desired_chain[p], follow_t)
		leg_chain_points[i] = new_chain

		var local_points := PackedVector2Array()
		local_points.resize(new_chain.size())
		for p in new_chain.size():
			local_points[p] = to_local(new_chain[p])
		line.points = local_points

#classic FABRIK solve: chain_in seeds the elbow direction so the pose stays continuous frame to frame instead of popping
func solve_leg_ik(chain_in: PackedVector2Array, root: Vector2, target_pos: Vector2, segment_length: float, iterations: int) -> PackedVector2Array:
	var n := chain_in.size()
	if n < 2:
		return chain_in
	var points := chain_in.duplicate()
	points[0] = root

	var total_length: float = segment_length * float(n - 1)
	var dist_to_target: float = root.distance_to(target_pos)

	if dist_to_target >= total_length: #target unreachable this frame - stretch straight toward it
		var dir := safe_dir(target_pos - root, Vector2.RIGHT)
		for i in range(1, n):
			points[i] = points[i - 1] + dir * segment_length
		return points

	for _iter in iterations:
		#backward pass: pin the tip to the target, walk back toward the root
		points[n - 1] = target_pos
		for i in range(n - 2, -1, -1):
			var dir := safe_dir(points[i] - points[i + 1], Vector2.RIGHT)
			points[i] = points[i + 1] + dir * segment_length
		#forward pass: pin the root, walk back out toward the tip
		points[0] = root
		for i in range(1, n):
			var dir := safe_dir(points[i] - points[i - 1], Vector2.RIGHT)
			points[i] = points[i - 1] + dir * segment_length
		if points[n - 1].distance_to(target_pos) < 0.5:
			break
	return points

func safe_dir(v: Vector2, fallback: Vector2) -> Vector2:
	if v.length_squared() < 0.0001:
		return fallback
	return v.normalized()

#procedural forward-kinematics curl used whenever a leg has no active target: spirals the tentacle
#in toward the body with a gentle idle wiggle, instead of just going limp or snapping away
func get_curl_chain(hip_global: Vector2, leg_index: int, t: float) -> PackedVector2Array:
	var chain := PackedVector2Array()
	chain.resize(leg_segment_count + 1)
	chain[0] = hip_global

	var base_dir: Vector2 = hip_global - global_position
	var angle: float = safe_dir(base_dir, Vector2.RIGHT.rotated(leg_index * TAU / 8.0)).angle()
	var phase: float = leg_index * 0.9
	var pos := hip_global

	for s in leg_segment_count:
		var segment_progress: float = float(s + 1) / float(leg_segment_count) #tip wiggles more than the base
		var wiggle: float = sin(t * leg_curl_speed + phase + s * 0.7) * leg_curl_wiggle_amount * segment_progress
		angle += leg_curl_amount + wiggle
		pos += Vector2(leg_segment_length, 0).rotated(angle)
		chain[s + 1] = pos

	return chain

### SIGNALS ###

func _on_PlayerDetector_body_entered(body):
	target = body.owner
	if state == "idle":
		change_state("popin")

func _on_PlayerDetector_body_exited(_body):
	target = null
