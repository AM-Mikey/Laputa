extends Enemy

const TX_0 = preload("res://assets/Actor/Enemy/Beetle.png")
const TX_1 = preload("res://assets/Actor/Enemy/Beetle1.png")

var move_dir = Vector2.LEFT
@export var wall_dir = Vector2.LEFT:
	set(val):
		up_direction = -val
		wall_dir = val
@export var difficulty := 0
var idle_time: float
var fly_cooldown_time = 2.0
var fly_speed = Vector2(100, 100)
var collision_shape_data: Dictionary

func setup():
	gravity = 0
	collision_shape_data = get_collision_shape_data()
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
			$CenteredPivot/PlayerCast.enabled = true
			$CenteredPivot/WorldCast.enabled = true
			change_state("idlescan")



func _on_physics_process(_delta):
	if disabled or dead or Engine.is_editor_hint(): return
	velocity = calc_velocity(move_dir, false) #no gravity
	move_and_slide()



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
	var collider = $CenteredPivot/PlayerCast.get_collider()
	var world_collider = $CenteredPivot/WorldCast.get_collider()

	if collider and world_collider:
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
			_:
				change_state("idlescan")
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
		"idle", "idlescan":
			target_collision_name = "cling"
			for i in collision_shape_data:
				if collision_shape_data[i][0] == "cling":
					var curr_collision_node: CollisionShape2D = get_node(i)
					var base_rot = collision_shape_data[i][1]
					var base_pos = collision_shape_data[i][2]
					rotate_collision_shape(curr_collision_node, new_shape_rot, base_rot, base_pos)
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
