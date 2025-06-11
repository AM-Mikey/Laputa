extends Enemy

const TX_0 = preload("res://assets/Actor/Enemy/Beetle.png")
const TX_1 = preload("res://assets/Actor/Enemy/Beetle1.png")
const TX_2 = preload("res://assets/Actor/Enemy/Beetle2.png")
const TX_3 = preload("res://assets/Actor/Enemy/Beetle3.png")

@export var move_dir = Vector2.LEFT
@export var wall_dir = Vector2.LEFT
@export var difficulty:= 0
var idle_time: float
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
			change_state("platformcrawl")
		3:
			hp = 4
			reward = 5
			damage_on_contact = 4
			$Sprite2D.texture = TX_3
	collision_shape_data = get_collision_shape_data()



func _on_physics_process(_delta):
	if disabled or dead or Engine.is_editor_hint(): return
	#if not is_on_floor():
		#move_dir.y = 0 #don't allow them to jump if they are midair

	velocity = calc_velocity(velocity, move_dir, speed, false) #no gravity
	move_and_slide()
	#animate()



### STATES ###

func enter_idle():
	match move_dir.x:
		-1.0: 
			$Sprite2D.flip_h = true
			$Sprite2D.rotation_degrees = -90
		1.0: 
			$Sprite2D.flip_h = false
			$Sprite2D.rotation_degrees = 90
	match move_dir.y:
		-1.0:
			$Sprite2D.rotation_degrees = 0
		1.0:
			$Sprite2D.rotation_degrees = 180
			$Sprite2D.flip_h = !$Sprite2D.flip_h
		
	set_collision_shapes()
	speed = Vector2.ZERO
	$AnimationPlayer.play("Idle")
	await get_tree().create_timer(idle_time).timeout
	change_state("fly")

func enter_idlescan():
	match move_dir.x:
		-1.0: 
			$Sprite2D.flip_h = true
			$Sprite2D.rotation_degrees = -90
		1.0: 
			$Sprite2D.flip_h = false
			$Sprite2D.rotation_degrees = 90
	match move_dir.y:
		-1.0:
			$Sprite2D.rotation_degrees = 0
		1.0:
			$Sprite2D.rotation_degrees = 180
			$Sprite2D.flip_h = !$Sprite2D.flip_h
		
	set_collision_shapes()
	speed = Vector2.ZERO
	$AnimationPlayer.play("Idle")

func do_idlescan():
	var collider
	match move_dir.x:
		-1.0:
			collider = $PlayerRightCast.get_collider()
		1.0:
			collider = $PlayerLeftCast.get_collider()
	match move_dir.y:
		-1.0:
			collider = $PlayerUpCast.get_collider()
		1.0:
			collider = $PlayerDownCast.get_collider()

	if collider:
		if collider is TileMap:
			return
		change_state("fly")
		return

func enter_fly():
	match move_dir.x:
		-1.0: $Sprite2D.flip_h = false
		1.0: $Sprite2D.flip_h = true
		#else have it track the player
		0.0: $Sprite2D.flip_h = sign(pc.global_position.x - global_position.x) == 1
	$Sprite2D.rotation_degrees = 0
	set_collision_shapes()
	speed = fly_speed
	$AnimationPlayer.play("Fly")


func do_fly():
	var collider
	match move_dir.x:
		-1.0: collider = $LeftCast.get_collider()
		1.0: collider = $RightCast.get_collider()
	match move_dir.y:
		-1.0: collider = $DownCast.get_collider()
		1.0: collider = $UpCast.get_collider()
	
	if collider:
		move_dir *= -1 #flip
		if difficulty == 0:
			change_state("idle")
		elif difficulty == 1:
			change_state("idlescan")
		return

func enter_platformcrawl():
	$AnimationPlayer.play("Crawl")
	speed = crawl_speed
	

	
	
func do_platformcrawl():
	
	var collider
	var edge1_collider
	var edge2_collider
	
	match move_dir.x:
		-1.0:
			collider = $LeftCast.get_collider()
		1.0:
			collider = $RightCast.get_collider()
	match move_dir.y:
		-1.0:
			collider = $DownCast.get_collider()
		1.0:
			collider = $UpCast.get_collider()
	
	match wall_dir:
		Vector2.LEFT:
			edge1_collider = $LeftCastU.get_collider()
			edge2_collider = $LeftCastD.get_collider()
		Vector2.RIGHT:
			edge1_collider = $RightCastU.get_collider()
			edge2_collider = $RightCastD.get_collider()
		Vector2.UP:
			edge1_collider = $UpCastL.get_collider()
			edge2_collider = $UpCastR.get_collider()
		Vector2.DOWN:
			edge1_collider = $DownCastL.get_collider()
			edge2_collider = $DownCastR.get_collider()
	
	if collider:
		move_dir *= -1
	if edge1_collider:
		print("kkdsaokas")
	if !edge1_collider or !edge2_collider:
		move_dir *= -1
		print("piss")

### HELPERS ###

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
	
	var new_shape_rot = 90 + rad_to_deg(move_dir.angle()) #90 * move_dir.x
	
	match state:
		"idle", "crawl", "idlescan":
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
