extends Enemy

const TX_0 = preload("res://assets/Actor/Enemy/Beetle.png")
const TX_1 = preload("res://assets/Actor/Enemy/Beetle1.png")
const TX_2 = preload("res://assets/Actor/Enemy/Beetle2.png")
const TX_3 = preload("res://assets/Actor/Enemy/Beetle3.png")

var move_dir = Vector2.LEFT
@export var wall_dir = Vector2.LEFT:
	set(val):
		up_direction = -val
		wall_dir = val
@export var crawl_start_dir = Vector2.ZERO
var doing_crawl_start_dir = false
@export var difficulty:= 0
var idle_time: float
var fly_cooldown_time = 2.0
var flip_cooldown_time = 1.0
var fly_speed = Vector2(100, 100)
var crawl_speed = Vector2(20, 20)
var collision_shape_data: Dictionary

func setup():
	gravity = 0
	match difficulty:
		0:
			hp = 2
			reward = 1
			damage_on_contact = 1
			idle_time = 2.0
			$Sprite2D.texture = TX_0
			change_state("idle")
		1:
			hp = 2
			reward = 2
			damage_on_contact = 2
			$Sprite2D.texture = TX_1
			change_state("idlescan")
		2:
			hp = 3
			reward = 4
			damage_on_contact = 2
			$Sprite2D.texture = TX_2
			if crawl_start_dir != Vector2.ZERO:
				doing_crawl_start_dir = true
			change_state("platformcrawl")
		#3:
			#hp = 4
			#reward = 5
			#damage_on_contact = 4
			#$Sprite2D.texture = TX_3
	collision_shape_data = get_collision_shape_data()



func _on_physics_process(_delta):
	if disabled or dead or Engine.is_editor_hint(): return
	#if not is_on_floor():
		#move_dir.y = 0 #don't allow them to jump if they are midair


	velocity = calc_velocity(move_dir, false) #no gravity
	if (state == "turn_edge"):
		velocity += wall_dir * 10.0

	move_and_slide()
	#animate()



### STATES ###

func enter_idle(_last_state): #level 0
	move_dir = wall_dir * -1
	match wall_dir:
		Vector2.LEFT: #face up
			$Sprite2D.flip_h = false
			$Sprite2D.rotation_degrees = 90
		Vector2.RIGHT: #face up
			$Sprite2D.flip_h = true
			$Sprite2D.rotation_degrees = -90
		Vector2.UP: #face same dir used in fly
			$Sprite2D.rotation_degrees = 180
			$Sprite2D.flip_h = !$Sprite2D.flip_h
		Vector2.DOWN: #face same dir used in fly
			$Sprite2D.rotation_degrees = 0
	set_collision_shapes()
	speed = Vector2.ZERO
	$AnimationPlayer.play("Idle")
	await get_tree().create_timer(idle_time, false, true).timeout
	change_state("fly")


func enter_idlescan(_last_state): #level 1
	move_dir = wall_dir * -1
	match wall_dir:
		Vector2.LEFT: #face up
			$Sprite2D.flip_h = false
			$Sprite2D.rotation_degrees = 90
		Vector2.RIGHT: #face up
			$Sprite2D.flip_h = true
			$Sprite2D.rotation_degrees = -90
		Vector2.UP: #face same dir used in fly
			$Sprite2D.rotation_degrees = 180
			$Sprite2D.flip_h = !$Sprite2D.flip_h
		Vector2.DOWN: #face same dir used in fly
			$Sprite2D.rotation_degrees = 0
	set_collision_shapes()
	speed = Vector2.ZERO
	$AnimationPlayer.play("Idle")

func do_idlescan():
	var collider
	match wall_dir:
		Vector2.LEFT:
			collider = $PlayerRightCast.get_collider()
		Vector2.RIGHT:
			collider = $PlayerLeftCast.get_collider()
		Vector2.UP:
			collider = $PlayerDownCast.get_collider()
		Vector2.DOWN:
			collider = $PlayerUpCast.get_collider()

	if collider:
		if collider is TileMapLayer:
			return
		if $FlyCooldown.is_stopped():
			change_state("fly")
			return

func enter_fly(_last_state):
	if (!pc or pc.dead): # In case the player die
		match difficulty:
			0:
				change_state("idle")
			1:
				change_state("idlescan")
			2:
				change_state("platformcrawl")
		return
	$FlyCooldown.start(fly_cooldown_time)
	match move_dir.x:
		-1.0: $Sprite2D.flip_h = false
		1.0: $Sprite2D.flip_h = true
		0.0: $Sprite2D.flip_h = sign(pc.global_position.x - global_position.x) == 1 #else have it track the player
	$Sprite2D.rotation_degrees = 0
	set_collision_shapes()
	speed = fly_speed
	$AnimationPlayer.play("Fly")

func do_fly():
	var collider
	match move_dir:
		Vector2.LEFT: collider = $LeftCast.get_collider()
		Vector2.RIGHT: collider = $RightCast.get_collider()
		Vector2.UP: collider = $UpCast.get_collider()
		Vector2.DOWN: collider = $DownCast.get_collider()

	if collider:
		move_and_collide(move_dir * 2)
		match difficulty:
			0:
				wall_dir *= -1
				change_state("idle")
			1:
				wall_dir *= -1
				change_state("idlescan")
			2:
				wall_dir *= -1 #wall_dir = move_dir * -1
				#var random_sign = 1 - 2 * (randi() % 2) #random direction after land
				#move_dir = wall_dir.rotated(deg_to_rad(90 * random_sign))
				change_state("platformcrawl")
				return

func enter_platformcrawl(last_state): #level 2
	if (last_state != "turn_edge"):
		if not doing_crawl_start_dir:
			var random_sign_float: float = 1 - 2 * (randi() % 2)
			if wall_dir == Vector2.LEFT or wall_dir == Vector2.RIGHT:
				move_dir = Vector2(0, random_sign_float)
			if wall_dir == Vector2.UP or wall_dir == Vector2.DOWN:
				move_dir = Vector2(random_sign_float, 0)
		else:
			move_dir = crawl_start_dir
			doing_crawl_start_dir = false #turn off after we're done
		set_collision_shapes()
		get_crawl_sprite()
	speed = crawl_speed

func exit_platformcrawl(_next_state):
	if (!$FlipCooldown.is_stopped()):
		$FlipCooldown.stop()

func do_platformcrawl():
	var wall_collider
	var edge_collider
	var player_collider
	var world_collider

	var edge_top_rc: RayCast2D
	var edge_top_rc2: RayCast2D
	var edge_bottom_rc: RayCast2D

	match wall_dir:
		Vector2.LEFT:
			if move_dir == Vector2.UP:
				edge_collider = $CenteredPivot/FloorCastL.get_collider()
				edge_top_rc = $CenteredPivot/MovableEdgeL1
				edge_top_rc2 = $CenteredPivot/MovableEdgeL3
				edge_bottom_rc = $CenteredPivot/MovableEdgeL2
			elif move_dir == Vector2.DOWN:
				edge_collider = $CenteredPivot/FloorCastR.get_collider()
				edge_top_rc = $CenteredPivot/MovableEdgeR1
				edge_top_rc2 = $CenteredPivot/MovableEdgeR3
				edge_bottom_rc = $CenteredPivot/MovableEdgeR2
			player_collider = $PlayerRightCast.get_collider()
			world_collider = $WorldRightCast.get_collider()
		Vector2.RIGHT:
			if move_dir == Vector2.UP:
				edge_collider = $CenteredPivot/FloorCastR.get_collider()
				edge_top_rc = $CenteredPivot/MovableEdgeR1
				edge_top_rc2 = $CenteredPivot/MovableEdgeR3
				edge_bottom_rc = $CenteredPivot/MovableEdgeR2
			elif move_dir == Vector2.DOWN:
				edge_collider = $CenteredPivot/FloorCastL.get_collider()
				edge_top_rc = $CenteredPivot/MovableEdgeL1
				edge_top_rc2 = $CenteredPivot/MovableEdgeL3
				edge_bottom_rc = $CenteredPivot/MovableEdgeL2
			player_collider = $PlayerLeftCast.get_collider()
			world_collider = $WorldLeftCast.get_collider()
		Vector2.UP:
			if move_dir == Vector2.LEFT:
				edge_collider = $CenteredPivot/FloorCastR.get_collider()
				edge_top_rc = $CenteredPivot/MovableEdgeR1
				edge_top_rc2 = $CenteredPivot/MovableEdgeR3
				edge_bottom_rc = $CenteredPivot/MovableEdgeR2
			elif move_dir == Vector2.RIGHT:
				edge_collider = $CenteredPivot/FloorCastL.get_collider()
				edge_top_rc = $CenteredPivot/MovableEdgeL1
				edge_top_rc2 = $CenteredPivot/MovableEdgeL3
				edge_bottom_rc = $CenteredPivot/MovableEdgeL2
			player_collider = $PlayerDownCast.get_collider()
			world_collider = $WorldDownCast.get_collider()
		Vector2.DOWN:
			if move_dir == Vector2.LEFT:
				edge_collider = $CenteredPivot/FloorCastL.get_collider()
				edge_top_rc = $CenteredPivot/MovableEdgeL1
				edge_top_rc2 = $CenteredPivot/MovableEdgeL3
				edge_bottom_rc = $CenteredPivot/MovableEdgeL2
			elif move_dir == Vector2.RIGHT:
				edge_collider = $CenteredPivot/FloorCastR.get_collider()
				edge_top_rc = $CenteredPivot/MovableEdgeR1
				edge_top_rc2 = $CenteredPivot/MovableEdgeR3
				edge_bottom_rc = $CenteredPivot/MovableEdgeR2
			player_collider = $PlayerUpCast.get_collider()
			world_collider = $WorldUpCast.get_collider()
	if is_on_wall(): #turn around from wall
		if $FlipCooldown.is_stopped():
			$FlipCooldown.start(flip_cooldown_time)
			move_dir *= -1
			get_crawl_sprite()
	elif !edge_collider: #At edge
		if (!edge_top_rc.is_colliding() and !edge_top_rc2.is_colliding() and edge_bottom_rc.is_colliding()):#turn corner from ledge
			change_state("pre_turn_edge")
		else: #turn around if no valid edge to turn
			if !(just_spawned):
				move_dir *= -1
				get_crawl_sprite()


	if player_collider:
		if player_collider is TileMapLayer:
			return
		if world_collider:
			#print("gotplayer")
			if $FlyCooldown.is_stopped():
				move_dir = wall_dir * -1
				change_state("fly")
				return


#region Pre turn corner
func enter_pre_turn_corner(prev_state):
	if (prev_state != "platformcrawl"):
		change_state("platformcrawl")

func do_pre_turn_edge():
	var oppos_edge_collider
	match wall_dir:
		Vector2.LEFT:
			if move_dir == Vector2.UP:
				oppos_edge_collider = $CenteredPivot/FloorCastR.get_collider()
			elif move_dir == Vector2.DOWN:
				oppos_edge_collider = $CenteredPivot/FloorCastL.get_collider()
		Vector2.RIGHT:
			if move_dir == Vector2.UP:
				oppos_edge_collider = $CenteredPivot/FloorCastL.get_collider()
			elif move_dir == Vector2.DOWN:
				oppos_edge_collider = $CenteredPivot/FloorCastR.get_collider()
		Vector2.UP:
			if move_dir == Vector2.LEFT:
				oppos_edge_collider = $CenteredPivot/FloorCastL.get_collider()
			elif move_dir == Vector2.RIGHT:
				oppos_edge_collider = $CenteredPivot/FloorCastR.get_collider()
		Vector2.DOWN:
			if move_dir == Vector2.LEFT:
				oppos_edge_collider = $CenteredPivot/FloorCastR.get_collider()
			elif move_dir == Vector2.RIGHT:
				oppos_edge_collider = $CenteredPivot/FloorCastL.get_collider()

	if (!oppos_edge_collider):
		change_state("turn_edge")

#region Turn Corner
var start_move_dir: Vector2 = Vector2.RIGHT
var start_wall_dir: Vector2 = Vector2.RIGHT
var start_sprite_rotation: float = 0.0
var allow_turn_edge_do: bool = false
func enter_turn_edge(_prev_state):
	allow_turn_edge_do = false
	start_move_dir = move_dir
	start_wall_dir = wall_dir
	start_sprite_rotation = $Sprite2D.rotation
	var turn_degree: float = 0
	match wall_dir:
		Vector2.LEFT:
			if move_dir == Vector2.UP:
				turn_degree = -PI / 2
			elif move_dir == Vector2.DOWN:
				turn_degree = PI / 2
		Vector2.RIGHT:
			if move_dir == Vector2.UP:
				turn_degree = PI / 2
			elif move_dir == Vector2.DOWN:
				turn_degree = -PI / 2
		Vector2.UP:
			if move_dir == Vector2.LEFT:
				turn_degree = PI / 2
			elif move_dir == Vector2.RIGHT:
				turn_degree = -PI / 2
		Vector2.DOWN:
			if move_dir == Vector2.LEFT:
				turn_degree = -PI / 2
			elif move_dir == Vector2.RIGHT:
				turn_degree = PI / 2

	var tween_time: float =  PI / 2 / (crawl_speed.x / 4.5)
	var turn_corner_tween: Tween = get_tree().create_tween()
	turn_corner_tween.tween_method(tween_move_dir, 0.0, turn_degree, tween_time)
	await turn_corner_tween.finished
	move_dir = convert_minus_zero_to_zero(start_move_dir.rotated(turn_degree))
	wall_dir = convert_minus_zero_to_zero(start_wall_dir.rotated(turn_degree))
	allow_turn_edge_do = true

# rotated() can return a vector component of -0.0 which does not equal to 0.0 and mess with match statement
func convert_minus_zero_to_zero(vec: Vector2):
	if is_zero_approx(vec.x):
		vec.x = 0.0
	if is_zero_approx(vec.y):
		vec.y = 0.0
	return vec


func tween_move_dir(curr_prog_angle):
	move_dir = start_move_dir.rotated(curr_prog_angle)
	wall_dir = start_wall_dir.rotated(curr_prog_angle)
	$Sprite2D.rotation = start_sprite_rotation + curr_prog_angle
	set_collision_shapes()

func do_turn_edge():
	if !allow_turn_edge_do:
		return

	if (is_on_floor()):
		change_state("platformcrawl")

#endregion
### HELPERS ###

func get_crawl_sprite(): #TODO fix
	$AnimationPlayer.play("Crawl")
	match wall_dir:
		Vector2.LEFT:
			$Sprite2D.rotation_degrees = 90
			if move_dir == Vector2.UP:
				$Sprite2D.flip_h = false
			elif move_dir == Vector2.DOWN:
				$Sprite2D.flip_h = true
		Vector2.RIGHT:
			$Sprite2D.rotation_degrees = 270
			if move_dir == Vector2.UP:
				$Sprite2D.flip_h = true
			elif move_dir == Vector2.DOWN:
				$Sprite2D.flip_h = false
		Vector2.UP:
			$Sprite2D.rotation_degrees = 180
			if move_dir == Vector2.LEFT:
				$Sprite2D.flip_h = true
			elif move_dir == Vector2.RIGHT:
				$Sprite2D.flip_h = false
		Vector2.DOWN:
			$Sprite2D.rotation_degrees = 0
			if move_dir == Vector2.LEFT:
				$Sprite2D.flip_h = false
			elif move_dir == Vector2.RIGHT:
				$Sprite2D.flip_h = true


func get_collision_shape_data() -> Dictionary:
	var out = {}
	for i in get_children():
		if i is CollisionShape2D:
			out[String(i.name)] = [i.name.to_lower(), i.rotation_degrees, i.position]
	for i in $Hurtbox.get_children():
		if i is CollisionShape2D:
			out["Hurtbox/" + i.name] = [i.name.to_lower(), i.rotation_degrees, i.position]
	for i in $Hitbox.get_children():
		if i is CollisionShape2D:
			out["Hitbox/" + i.name] = [i.name.to_lower(), i.rotation_degrees, i.position]
	return out


func set_collision_shapes():
	for key in collision_shape_data.keys():
		get_node(key).visible = false
		get_node(key).disabled = true

	var new_shape_rot = -90 + rad_to_deg(wall_dir.angle()) #90 * move_dir.x

	$CenteredPivot.rotation_degrees = new_shape_rot

	match state:
		"idle", "crawl", "platformcrawl", "idlescan", "turn_edge":
			for i in collision_shape_data:
				var is_crawl = collision_shape_data[i][0] == "crawl"
				get_node(i).disabled = !is_crawl
				get_node(i).visible = is_crawl
				if is_crawl:
					var base_rot = collision_shape_data[i][1]
					var base_pos = collision_shape_data[i][2]
					rotate_collision_shape(get_node(i), new_shape_rot, base_rot, base_pos)
		"crawldiagonal":
			for i in collision_shape_data:
				var is_crawldiagonal = collision_shape_data[i][0] == "crawldiagonal"
				get_node(i).disabled = !is_crawldiagonal
				get_node(i).visible = is_crawldiagonal
		"fly":
			for i in collision_shape_data:
				var is_fly = collision_shape_data[i][0] == "fly"
				get_node(i).disabled = !is_fly
				get_node(i).visible = is_fly


func rotate_collision_shape(shape, deg, base_deg, base_pos):
	var pivot = $Pivot.position
	var offset = base_pos - pivot
	var rad = deg_to_rad(deg)
	var rotated_offset = offset.rotated(rad)
	shape.position = pivot + rotated_offset
	shape.rotation_degrees = deg + base_deg
