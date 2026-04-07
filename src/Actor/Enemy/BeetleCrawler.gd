extends Enemy

##TODO: add "boundary" waypoint option to give them a stop if needed
##force snap them to the center of a block before fly or make them wait until they are

const ICON = preload("res://assets/Actor/Enemy/BeetleCrawlerIcon.png")
const TX_0 = preload("res://assets/Actor/Enemy/BeetleCrawler.png")
const TX_1 = preload("res://assets/Actor/Enemy/BeetleCrawler1.png")

var move_dir = Vector2.LEFT
var saved_move_dir: Vector2
var fly_dir = Vector2.UP
var wall_dir = Vector2.LEFT:
	set(val):
		up_direction = -val
		wall_dir = val
var crawl_dir = Vector2.LEFT
@export var difficulty := 0
var max_difficulty := 1

var idle_time: float
var flip_cooldown_time = 1.0
var fly_cooldown_time = 1.0
var exterior_corner_time = 0.4
var interior_corner_time = 0.3
var fly_speed = Vector2(100, 100)
var crawl_speed = Vector2(20, 20)


func setup():
	fly_dir = $FlyVector.direction
	wall_dir = fly_dir * -1
	crawl_dir.x = fly_dir.cross($CrawlVector.direction)
	$CenteredPivot.scale.x = crawl_dir.x * -1
	$Sprite2D.scale.x = crawl_dir.x * -1
	rotation = fly_dir.angle() + deg_to_rad(90)
	gravity = 0
	move_dir = crawl_dir.rotated(rotation)
	match difficulty:
		0:
			hp = 3
			reward = 4
			damage_on_contact = 2
			$Sprite2D.texture = TX_0
		1:
			hp = 4
			reward = 5
			damage_on_contact = 2
			$Sprite2D.texture = TX_1
	change_state("crawl")


func _on_physics_process(_delta):
	if disabled or dead or Engine.is_editor_hint(): return
	velocity = calc_velocity(move_dir, false) #no gravity
	move_and_slide()



### STATES ###

func enter_fly(_last_state):
	if (!pc or pc.dead): # In case the player die
		change_state("crawl")
		return

	match move_dir.x:
		-1.0: $Sprite2D.scale.x = 1.0
		1.0: $Sprite2D.scale.x = -1.0
		0.0: $Sprite2D.scale.x = sign(pc.global_position.x - global_position.x) == 1 #else have it track the player

	align_to_nearest_tile()

	rotation_degrees = 0
	set_collision_shapes("fly")
	speed = fly_speed
	$AnimationPlayer.play("Fly")


func do_fly(_delta):
	var cast: RayCast2D = null
	if move_dir.dot(Vector2.LEFT) > 0.9:
		cast = $LeftCast
	elif move_dir.dot(Vector2.RIGHT) > 0.9:
		cast = $RightCast
	elif move_dir.dot(Vector2.UP) > 0.9:
		cast = $UpCast
	elif move_dir.dot(Vector2.DOWN) > 0.9:
		cast = $DownCast

	if cast == null or not cast.is_colliding():
		return

	wall_dir *= -1
	fly_dir *= -1
	var random_sign = 1 - 2 * (randi() % 2)
	crawl_dir.x = random_sign
	$CenteredPivot.scale.x = crawl_dir.x * -1
	$Sprite2D.scale.x = crawl_dir.x * -1
	rotation = wall_dir.angle() - deg_to_rad(90)
	move_dir = crawl_dir.rotated(rotation)

	var collision_point = cast.get_collision_point()
	global_position = collision_point
	$FlyCooldown.start(fly_cooldown_time)
	change_state("crawl")
	return

func align_to_nearest_tile():
	#move it out of the wall
	if move_dir.dot(Vector2.LEFT) > 0.9:
		global_position += Vector2(-6, 0)
		global_position.y = floori(global_position.y / 16.0) * 16.0 + 16.0 #snap height
	elif move_dir.dot(Vector2.RIGHT) > 0.9:
		global_position += Vector2(6, 0)
		global_position.y = floori(global_position.y / 16.0) * 16.0 + 16.0 #snap height
	elif move_dir.dot(Vector2.UP) > 0.9:
		pass
		global_position.x = floori(global_position.x / 16.0) * 16.0 + (16.0 / 2.0) #snap width
	elif move_dir.dot(Vector2.DOWN) > 0.9:
		global_position += Vector2(0, 14)
		global_position.x = floori(global_position.x / 16.0) * 16.0 + (16.0 / 2.0) #snap width



func enter_crawl(_last_state):
	$AnimationPlayer.play("Crawl")
	speed = crawl_speed
	set_collision_shapes("crawl")

func do_crawl(_delta):
	# Prevent pixel gaps between the beetle and the terrain by making the beetle stick closer to the wall
	var collision := move_and_collide(wall_dir * 5, true)
	# The first move_and_collide doesn't move the body, instead it tests if the body *would* collide if moved
	if collision != null:
		if collision.get_travel().length() > 0.0001:
			move_and_collide(wall_dir * 5)

	var player_collider = $CenteredPivot/PlayerCast.get_collider()
	var world_collider = $CenteredPivot/WorldCast.get_collider()
	if !%FloorCast.is_colliding(): #At edge
		if %ExteriorCornerCast.is_colliding() && %ExteriorCornerDetector.get_overlapping_bodies() == []: #turn corner
			change_state("exterior_corner")
		elif %ExteriorCornerCast.is_colliding() || %ExteriorCornerDetector.get_overlapping_bodies() == []: #turn around from unturnable edge
			flip_check()

	if player_collider && world_collider && difficulty == 1:
		if player_collider is TileMapLayer || player_collider.get_collision_layer_value(4): #for when it hits world before player
			pass
		elif $FlyCooldown.is_stopped():
			if world_cast_check():
				move_dir = wall_dir * -1
				change_state("fly")
				return

	if %InteriorCornerCast.is_colliding() && %InteriorCornerCast2.is_colliding(): #At wall
		change_state("interior_corner")
	elif %InteriorCornerCast.is_colliding() || %InteriorCornerCast2.is_colliding(): #
		flip_check()

func exit_crawl(_next_state):
	print("exit crawl")
	if (!$FlipCooldown.is_stopped()):
		$FlipCooldown.stop()

func flip_check():
	print("tried to flip")
	if $FlipCooldown.is_stopped():
		$FlipCooldown.start(flip_cooldown_time)
		move_dir *= -1.0
		crawl_dir *= -1.0
		$CenteredPivot.scale.x *= -1.0
		$Sprite2D.scale.x *= -1.0



func enter_exterior_corner(_last_state):
	$AnimationPlayer.play("ExteriorCorner")
	$CollisionShape2D.disabled = true
	saved_move_dir = move_dir
	velocity = Vector2.ZERO
	move_dir = Vector2.ZERO
	$CornerTimer.start(exterior_corner_time)


func do_exterior_corner(_delta):
	if $CornerTimer.is_stopped():
		change_state("crawl")

func exit_exterior_corner(_next_state):
	global_position += saved_move_dir * 6 + wall_dir * 6
	rotation += deg_to_rad(90.0 * crawl_dir.x)
	move_dir = saved_move_dir.rotated(deg_to_rad(90.0 * crawl_dir.x))
	wall_dir = wall_dir.rotated(deg_to_rad(90.0 * crawl_dir.x))
	$CollisionShape2D.set_deferred("disabled", false)



func enter_interior_corner(_last_state):
	$AnimationPlayer.play("InteriorCorner")
	$CollisionShape2D.disabled = true
	saved_move_dir = move_dir
	velocity = Vector2.ZERO
	move_dir = Vector2.ZERO
	$CornerTimer.start(interior_corner_time)

func do_interior_corner(_delta):
	if $CornerTimer.is_stopped():
		change_state("crawl")

func exit_interior_corner(_next_state):
	global_position += saved_move_dir * 6 + wall_dir * -6
	rotation += deg_to_rad(-90.0 * crawl_dir.x)
	move_dir = saved_move_dir.rotated(deg_to_rad(-90.0 * crawl_dir.x))
	wall_dir = wall_dir.rotated(deg_to_rad(-90.0 * crawl_dir.x))
	$CollisionShape2D.set_deferred("disabled", false)


### HELPERS ###

func world_cast_check() -> bool:
	var world_cast = $CenteredPivot/WorldCast
	if not world_cast.is_colliding():
		printerr("ERROR: No opposite wall for beetle.")
		return false

	var normal = world_cast.get_collision_normal()
	var expected = wall_dir
	var is_valid = normal.dot(expected) > 0.9

	if not is_valid:
		printerr(
			"ERROR: Opposite wall for beetle with normal %s does not match expected %s."
			% [normal, expected]
		)
	return is_valid

func set_collision_shapes(shape_name):
	match shape_name:
		"crawl":
			$CollisionShape2D.disabled = false
			$Hurtbox/Crawl.disabled = false
			$Hitbox/Crawl.disabled = false
			$Fly.disabled = true
			$Hurtbox/Fly.disabled = true
			$Hitbox/Fly.disabled = true
		"fly":
			$CollisionShape2D.disabled = true
			$Hurtbox/Crawl.disabled = true
			$Hitbox/Crawl.disabled = true
			$Fly.disabled = false
			$Hurtbox/Fly.disabled = false
			$Hitbox/Fly.disabled = false

#func get_crawl_sprite():
	#$AnimationPlayer.play("Crawl")
	#var cross = wall_dir.cross(move_dir)
	#$Sprite2D.rotation = wall_dir.angle() + PI / 2
	#$Sprite2D.flip_h = cross < 0


#func get_collision_shape_data() -> Dictionary:
	#var out = {}
	#for i in get_children():
		#if i is CollisionShape2D:
			#out[String(i.name)] = [i.name.to_lower(), i.rotation_degrees, i.position]
	#for i in $Hurtbox.get_children():
		#if i is CollisionShape2D:
			#out["Hurtbox/" + i.name] = [i.name.to_lower(), i.rotation_degrees, i.position]
	#for i in $Hitbox.get_children():
		#if i is CollisionShape2D:
			#out["Hitbox/" + i.name] = [i.name.to_lower(), i.rotation_degrees, i.position]
	#return out


#func set_collision_shapes():
	#for key in collision_shape_data.keys():
		#get_node(key).disabled = true
		#get_node(key).visible = false
#
	#var new_shape_rot = -90 + rad_to_deg(wall_dir.angle()) #90 * move_dir.x
#
	#$CenteredPivot.rotation_degrees = new_shape_rot
#
	#var target_collision_name: String = ""
	#match state:
		#"idle", "crawl", "exterior_corner", "interior_corner":
			#target_collision_name = "CollisionShape2D"
			#for i in collision_shape_data:
				#if collision_shape_data[i][0] == "crawl":
					#var curr_collision_node: CollisionShape2D = get_node(i)
					#var base_rot = collision_shape_data[i][1]
					#var base_pos = collision_shape_data[i][2]
					#rotate_collision_shape(curr_collision_node, new_shape_rot, base_rot, base_pos)
		#"fly":
			#target_collision_name = "fly"
#
	#for i in collision_shape_data:
		#var curr_collision_node: CollisionShape2D = get_node(i)
		#if (collision_shape_data[i][0] == target_collision_name):
			#if (i == target_collision_name):
				#$CollisionShape2D.shape = curr_collision_node.shape
				#$CollisionShape2D.position = curr_collision_node.position
				#$CollisionShape2D.rotation = curr_collision_node.rotation
			#else:
				#curr_collision_node.disabled = false
				#curr_collision_node.visible = true


#func rotate_collision_shape(shape, deg, base_deg, base_pos):
	#var pivot = $Pivot.position
	#var offset = base_pos - pivot
	#var rad = deg_to_rad(deg)
	#var rotated_offset = offset.rotated(rad)
	#shape.position = pivot + rotated_offset
	#shape.rotation_degrees = deg + base_deg
