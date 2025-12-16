extends Enemy

const TX_0 = preload("res://assets/Actor/Enemy/Beetle.png")
const TX_1 = preload("res://assets/Actor/Enemy/Beetle1.png")
const TX_2 = preload("res://assets/Actor/Enemy/Beetle2.png")
const TX_3 = preload("res://assets/Actor/Enemy/Beetle3.png")

var move_dir = Vector2.LEFT
@export var wall_dir = Vector2.LEFT
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

	velocity = calc_velocity(velocity, move_dir, speed, false) #no gravity
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
	await get_tree().create_timer(idle_time).timeout
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

func enter_platformcrawl(_last_state): #level 2
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

func do_platformcrawl():
	var wall_collider
	var edge_collider
	var player_collider
	var world_collider


	match move_dir:
		Vector2.LEFT:
			wall_collider = $LeftCast.get_collider()
		Vector2.RIGHT:
			wall_collider = $RightCast.get_collider()
		Vector2.UP:
			wall_collider = $UpCast.get_collider()
		Vector2.DOWN:
			wall_collider = $DownCast.get_collider()

	match wall_dir:
		Vector2.LEFT:
			if move_dir == Vector2.UP:
				edge_collider = $LeftCastU.get_collider()
			elif move_dir == Vector2.DOWN:
				edge_collider = $LeftCastD.get_collider()
			player_collider = $PlayerRightCast.get_collider()
			world_collider = $WorldRightCast.get_collider()
		Vector2.RIGHT:
			if move_dir == Vector2.UP:
				edge_collider = $RightCastU.get_collider()
			elif move_dir == Vector2.DOWN:
				edge_collider = $RightCastD.get_collider()
			player_collider = $PlayerLeftCast.get_collider()
			world_collider = $WorldLeftCast.get_collider()
		Vector2.UP:
			if move_dir == Vector2.LEFT:
				edge_collider = $UpCastL.get_collider()
			elif move_dir == Vector2.RIGHT:
				edge_collider = $UpCastR.get_collider()
			player_collider = $PlayerDownCast.get_collider()
			world_collider = $WorldDownCast.get_collider()
		Vector2.DOWN:
			if move_dir == Vector2.LEFT:
				edge_collider = $DownCastL.get_collider()
			elif move_dir == Vector2.RIGHT:
				edge_collider = $DownCastR.get_collider()
			player_collider = $PlayerUpCast.get_collider()
			world_collider = $WorldUpCast.get_collider()

	if wall_collider: #flip from wall
		#print("flipwall")
		if $FlipCooldown.is_stopped():
			$FlipCooldown.start(flip_cooldown_time)
			move_dir *= -1
			get_crawl_sprite()
	elif !edge_collider: #flip from ledge
		#print("flipedge")
		if $FlipCooldown.is_stopped():
			speed = crawl_speed
			$FlipCooldown.start(flip_cooldown_time)
			move_dir *= -1
			get_crawl_sprite()
		else:
			speed = Vector2.ZERO #prevent from walking off edge
	if player_collider:
		if player_collider is TileMapLayer:
			return
		if world_collider:
			#print("gotplayer")
			if $FlyCooldown.is_stopped():
				move_dir = wall_dir * -1
				change_state("fly")
				return



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

	match state:
		"idle", "crawl", "platformcrawl", "idlescan":
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
