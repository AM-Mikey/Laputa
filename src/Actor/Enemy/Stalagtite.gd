extends Enemy

var target: Node

export var look_dir: Vector2 = Vector2.LEFT
var move_dir: Vector2 = Vector2.UP #start moving upwards constantly

var dropped = false
var panic_run = false
var touchdown = false

export var base_damage = 2
export var falling_damage = 4

func _ready():
	hp = 2
	level = 2
	damage_on_contact = base_damage
	speed = Vector2(100, 100)
	setup_collision()

func setup_collision():
	$RayCast2D.force_raycast_update()
	var tilemap = $RayCast2D.get_collider()
	#print(tilemap)
	$RayCast2D.queue_free()
	
	if tilemap != null:
		var target_pos = global_position
		var local_pos = tilemap.to_local(target_pos)
		var map_pos = tilemap.world_to_map(local_pos)
		var target_cell = tilemap.get_cellv(map_pos)
		
		var detector_length = 0
		
		while target_cell == -1:
			detector_length += 1
			map_pos.y += 1
			target_cell = tilemap.get_cellv(map_pos)
				
		$PlayerDetector.scale.y = detector_length
		print("dl: ", detector_length)
	else:
		printerr("ERROR: stalagtite could not find a colliding tilemap to setup collision")

func _physics_process(delta):
	if not dead:
		velocity = calculate_movevelocity(velocity, move_dir, speed)
		velocity = move_and_slide(velocity, FLOOR_NORMAL)
		
		if dropped == true:
			if is_on_floor() and touchdown == false: #check to see if they've landed before
				touchdown = true
				$PlayerDetector.queue_free()
				yield(get_tree().create_timer(0.01), "timeout") #delay to change damage back to base
				damage_on_contact = base_damage
				
				if look_dir == Vector2.LEFT:
					$AnimationPlayer.play("SquirmLeft")
				elif look_dir == Vector2.RIGHT:
					$AnimationPlayer.play("SquirmRight")
				
				yield($AnimationPlayer, "animation_finished")
				
				panic_run = true
				move_dir.x = look_dir.x

			if is_on_wall():
				move_dir.x *= -1
		
		animate()

func calculate_movevelocity(velocity: Vector2, move_dir, speed) -> Vector2:
	var out: = velocity
	
	out.x = speed.x * move_dir.x
	out.y += gravity * get_physics_process_delta_time()
	if move_dir.y < 0:
		out.y = speed.y * move_dir.y

	return out
	
	
	
func _on_PlayerDetector_body_entered(body):
	if visible == true:
		target = body
		drop()

func drop():
	$PlayerDetector.set_deferred("monitoring", false) #no longer needs to be triggered
	dropped = true
	move_dir.y = 0 #fall
	damage_on_contact = falling_damage


func animate():
	if move_dir == Vector2.UP:
		$AnimationPlayer.play("HangIdle")
			
	if panic_run == true:
		if move_dir == Vector2.LEFT:
			$AnimationPlayer.play("RunLeft")
		elif move_dir == Vector2.RIGHT:
			$AnimationPlayer.play("RunRight")
