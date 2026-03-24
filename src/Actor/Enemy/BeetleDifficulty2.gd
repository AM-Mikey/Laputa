extends Enemy

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
	move_dir = $MoveVector.direction
	wall_dir = $WallVector.direction
	gravity = 0
	collision_shape_data = get_collision_shape_data()
	match difficulty:
		2:
			hp = 3
			reward = 4
			damage_on_contact = 2
			$Sprite2D.texture = TX_2
			$CenteredPivot/PlayerCast.enabled = true
			$CenteredPivot/WorldCast.enabled = true
			$CenteredPivot/FloorCastL.enabled = true
			$CenteredPivot/FloorCastR.enabled = true
			$CenteredPivot/MovableEdgeL1.enabled = true
			$CenteredPivot/MovableEdgeL2.enabled = true
			$CenteredPivot/MovableEdgeL3.enabled = true
			$CenteredPivot/MovableEdgeR1.enabled = true
			$CenteredPivot/MovableEdgeR2.enabled = true
			$CenteredPivot/MovableEdgeR3.enabled = true
			if crawl_start_dir != Vector2.ZERO:
				doing_crawl_start_dir = true
			change_state("platformcrawl")



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
	if move_dir.dot(Vector2.LEFT) > 0.9: #close to Vector2.Left
		collider = $LeftCast.get_collider()
	elif move_dir.dot(Vector2.RIGHT) > 0.9:
		collider = $RightCast.get_collider()
	elif move_dir.dot(Vector2.UP) > 0.9:
		collider = $UpCast.get_collider()
	elif move_dir.dot(Vector2.DOWN) > 0.9:
		collider = $DownCast.get_collider()

	if collider:
		move_and_collide(move_dir * 2)
		match difficulty:
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

	player_collider = $CenteredPivot/PlayerCast.get_collider()
	world_collider = $CenteredPivot/WorldCast.get_collider()

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
	var cross = wall_dir.cross(move_dir)
	if abs(cross) > 0.9:
		turn_degree = sign(cross) * PI / 2

	var tween_time: float =  PI / 2 / (crawl_speed.x / 4.5)
	var turn_corner_tween: Tween = get_tree().create_tween()
	turn_corner_tween.tween_method(tween_move_dir, 0.0, turn_degree, tween_time)
	await turn_corner_tween.finished
	move_dir = convert_minus_zero_to_zero(start_move_dir.rotated(turn_degree))
	wall_dir = convert_minus_zero_to_zero(start_wall_dir.rotated(turn_degree))
	allow_turn_edge_do = true

# rotated() can return a vector component of -0.0 which does not equal to 0.0 and mess with match statement
func convert_minus_zero_to_zero(vec: Vector2): #TODO:remove and replace with approximation
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

func get_crawl_sprite():
	$AnimationPlayer.play("Crawl")
	var cross = wall_dir.cross(move_dir)
	$Sprite2D.rotation = wall_dir.angle() + PI / 2
	$Sprite2D.flip_h = cross < 0


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
		get_node(key).disabled = true
		get_node(key).visible = false

	var new_shape_rot = -90 + rad_to_deg(wall_dir.angle()) #90 * move_dir.x

	$CenteredPivot.rotation_degrees = new_shape_rot

	var target_collision_name: String = ""
	match state:
		"idle", "crawl", "platformcrawl", "idlescan", "turn_edge":
			target_collision_name = "crawl"
			for i in collision_shape_data:
				if collision_shape_data[i][0] == "crawl":
					var curr_collision_node: CollisionShape2D = get_node(i)
					var base_rot = collision_shape_data[i][1]
					var base_pos = collision_shape_data[i][2]
					rotate_collision_shape(curr_collision_node, new_shape_rot, base_rot, base_pos)
		"crawldiagonal":
			target_collision_name = "crawldiagonal"
		"fly":
			target_collision_name = "fly"

	for i in collision_shape_data:
		var curr_collision_node: CollisionShape2D = get_node(i)
		if (collision_shape_data[i][0] == target_collision_name):
			if (i == target_collision_name):
				$CollisionShape2D.shape = curr_collision_node.shape
				$CollisionShape2D.position = curr_collision_node.position
				$CollisionShape2D.rotation = curr_collision_node.rotation
			else:
				curr_collision_node.disabled = false
				curr_collision_node.visible = true


func rotate_collision_shape(shape, deg, base_deg, base_pos):
	var pivot = $Pivot.position
	var offset = base_pos - pivot
	var rad = deg_to_rad(deg)
	var rotated_offset = offset.rotated(rad)
	shape.position = pivot + rotated_offset
	shape.rotation_degrees = deg + base_deg
