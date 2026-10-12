extends Enemy

const ICON = preload("res://assets/Actor/Enemy/GeckoIcon.png")

const TX_0 = preload("res://assets/Actor/Enemy/Gecko.png")
const TOOLTIPS = [
"LV 0: need to write.",
]

var move_dir = Vector2.LEFT
var normal_dir = Vector2.UP
var wall_dir = Vector2.LEFT:
	set(val):
		up_direction = -val
		wall_dir = val
var active_player: Node
var player_in_detector := false


var crawl_speed = Vector2(20, 20)
var flee_speed = Vector2(100, 100)
var avoid_speed = Vector2(50, 50)
var idle_min_time = 1.0
var idle_max_time = 10.0
var crawl_min_time = 2.0
var crawl_max_time = 6.0
var flee_min_time = 1.0
var flee_max_time = 4.0
var avoid_min_time = 3.0
var avoid_max_time = 6.0
var flip_cooldown_time = 2.0

var fall_land_dir := Vector2.ZERO #global dir to crawl in after landing (zero = random)
var fall_drift_dir := Vector2.ZERO #global dir to drift in while falling
var fall_time := 0.0
var fall_start_y := 0.0
var min_fall_distance := 4.0 #px dropped before a floor contact counts as landing
var fall_drift_speed := 40.0
var land_time := 0.3

var avoid_cooldown_time := 1.5
var avoid_cooldown_left := 0.0 #wall/edge hit while this is > 0 sends avoid straight to flee
var flee_keep_dir := false #set when move_dir was already turned around before entering flee
var startup_flip_grace := 0.25
const BODY_CENTER_OFFSET := 7.0 #fall shape centre is 7px off the surface (matches the (0, -7) shape positions)


#TODO: dust particles for when running (ala minecraft cats)


func setup(): #Reminder: no function called can use await
	normal_dir = $NormalVector.direction.normalized()
	wall_dir = normal_dir * -1
	rotation = normal_dir.angle() + deg_to_rad(90)
	gravity = 0.0
	var tangent = normal_dir.rotated(deg_to_rad(90))
	var crawl_x = sign($CrawlVector.direction.dot(tangent))
	if crawl_x == 0.0:
		crawl_x = 1.0
	move_dir = Vector2(crawl_x, 0.0).rotated(rotation)
	update_facing()

	refresh_casts()
	$FlipCooldown.start(startup_flip_grace)

	hp = 2
	damage_on_contact = 2
	w.emit_signal("finished_spawn_entities_step")

	change_state("crawl")


func _on_physics_process(_delta):
	if disabled or dead or Engine.is_editor_hint(): return
	if state == "fall":
		velocity = calc_velocity(move_dir, true) #gravity + horizontal drift
	else:
		velocity = Vector2(move_dir.x * speed.x, move_dir.y * speed.y)
	move_and_slide()



func enter_idle(_delta):
	$AnimationPlayer.play("Idle")
	speed = Vector2.ZERO
	$IdleTimer.start(randf_range(idle_min_time, idle_max_time))


func enter_crawl(_last_state):
	$AnimationPlayer.play("Crawl")
	speed = crawl_speed
	$AnimationPlayer.speed_scale = 0.75
	$CrawlTimer.start(randf_range(crawl_min_time, crawl_max_time))

func do_crawl(_delta):
	# Prevent pixel gaps between the beetle and the terrain by making the beetle stick closer to the wall
	var collision := move_and_collide(wall_dir * 5, true)
	# The first move_and_collide doesn't move the body, instead it tests if the body *would* collide if moved
	if collision != null:
		if collision.get_travel().length() > 0.0001:
			move_and_collide(wall_dir * 5)

	flip_if_blocked()

func exit_crawl(_next_state):
	$AnimationPlayer.speed_scale = 1.0
	if (!$FlipCooldown.is_stopped()):
		$FlipCooldown.stop()


func enter_flee(_last_state):
	$AnimationPlayer.play("Crawl")
	$AnimationPlayer.speed_scale = 2.0
	speed = flee_speed
	$FleeTimer.start(randf_range(flee_min_time, flee_max_time))
	if flee_keep_dir: #already turned around, don't flip back into it
		flee_keep_dir = false
	else:
		move_dir *= -1.0
		update_facing()

func do_flee(_delta):
	# Prevent pixel gaps between the beetle and the terrain by making the beetle stick closer to the wall
	var collision := move_and_collide(wall_dir * 5, true)
	# The first move_and_collide doesn't move the body, instead it tests if the body *would* collide if moved
	if collision != null:
		if collision.get_travel().length() > 0.0001:
			move_and_collide(wall_dir * 5)

	if !%FloorCastL.is_colliding() && !%FloorCastR.is_colliding(): #past edge
		var drift = Vector2(sign(move_dir.x), 0.0)
		if abs(move_dir.x) < 0.5: #crawling vertically on a side wall: fall away from the wall
			drift = Vector2(-sign(wall_dir.x), 0.0)
		fall_land_dir = drift
		fall_drift_dir = drift
		stop_all_timers()
		change_state("fall")
	elif %LeftCast.is_colliding() || %RightCast.is_colliding(): #At wall
		if is_on_floor_surface():
			if is_heading_into_wall():
				force_flip() #flip cooldown must not let us run into the wall
		else:
			var away = get_wall_hit_away_dir()
			fall_land_dir = away
			fall_drift_dir = away
			stop_all_timers()
			change_state("fall")

func exit_flee(_next_state):
	$AnimationPlayer.speed_scale = 1.0
	if (!$FlipCooldown.is_stopped()):
		$FlipCooldown.stop()


func enter_fall(_last_state):
	$AnimationPlayer.play("Fall")
	fall_time = 0.0
	global_position += (normal_dir * BODY_CENTER_OFFSET).round() + Vector2(0.0, BODY_CENTER_OFFSET)
	fall_start_y = global_position.y #after the move, so the translation doesn't count as falling
	#turn upright
	normal_dir = Vector2.UP
	wall_dir = Vector2.DOWN
	rotation = 0.0
	gravity = base_gravity #TODO: not accounting for water gravity
	velocity = Vector2.ZERO
	move_dir = fall_drift_dir
	update_facing() #sprite was flipped for the old orientation; face the drift direction in the new one
	speed = Vector2(fall_drift_speed, fall_drift_speed)

func do_fall(delta):
	fall_time += delta
	if is_on_floor():
		#global_position.y = round(global_position.y) #snap to the exact pixel height
		change_state("land")


func enter_land(_last_state):
	$AnimationPlayer.play("Land")
	speed = Vector2.ZERO
	move_dir = Vector2.ZERO
	#velocity = Vector2.ZERO allow us to slide a bit
	$LandTimer.start(land_time)



func enter_avoid(_last_state):
	$AnimationPlayer.play("Crawl")
	$AnimationPlayer.speed_scale = 0.75
	speed = avoid_speed
	$AvoidTimer.start(randf_range(avoid_min_time, avoid_max_time))
	avoid_cooldown_left = avoid_cooldown_time


func do_avoid(delta):
	# Prevent pixel gaps between the beetle and the terrain by making the beetle stick closer to the wall
	var collision := move_and_collide(wall_dir * 5, true)
	# The first move_and_collide doesn't move the body, instead it tests if the body *would* collide if moved
	if collision != null:
		if collision.get_travel().length() > 0.0001:
			move_and_collide(wall_dir * 5)

	avoid_cooldown_left = max(avoid_cooldown_left - delta, 0.0)

	var local_dir_to_player = (active_player.global_position - global_position).rotated(-global_rotation)
	var away_x = -sign(local_dir_to_player.x)
	if away_x != 0.0:
		move_dir = Vector2(away_x, 0.0).rotated(global_rotation)
		update_facing()

	if is_heading_off_edge() || is_heading_into_wall():
		force_flip() #ignore the flip cooldown
		stop_all_timers()
		if avoid_cooldown_left > 0.0 || player_in_detector: #cornered quickly (or player still near)
			flee_keep_dir = true #already turned around, enter_flee must not flip again
			change_state("flee")
		else:
			change_state("crawl")


func exit_avoid(_next_state):
	$AnimationPlayer.speed_scale = 1.0
	if (!$FlipCooldown.is_stopped()):
		$FlipCooldown.stop()



### HELPERS ###

func _on_hit(_damage, _blood_direction, _hitbox):
	if state in ["crawl", "idle", "avoid"]:
		stop_all_timers()
		change_state("flee")

func is_on_floor_surface() -> bool:
	return wall_dir.dot(Vector2.DOWN) > 0.9

func flip_check():
	if $FlipCooldown.is_stopped():
		force_flip()

func force_flip():
	$FlipCooldown.start(flip_cooldown_time)
	move_dir *= -1.0
	update_facing()

func update_facing():
	var local_x = move_dir.rotated(-rotation).x
	if abs(local_x) < 0.01: return
	var facing = sign(local_x) #-1 = facing local left, +1 = facing local right
	$Sprite2D.scale.x = -facing
	$Hurtbox/CollisionShape2D.position = Vector2(-4.0 * facing, -7.0) #(4, -7) facing left, (-4, -7) facing right

func is_heading_into_wall() -> bool:
	var local_x = move_dir.rotated(-rotation).x
	return (%LeftCast.is_colliding() && local_x < 0.0) || (%RightCast.is_colliding() && local_x > 0.0)

func is_heading_off_edge() -> bool:
	var local_x = move_dir.rotated(-rotation).x
	return (!%FloorCastL.is_colliding() && local_x < 0.0) || (!%FloorCastR.is_colliding() && local_x > 0.0)

func flip_if_blocked():
	if !(is_heading_off_edge() || is_heading_into_wall()): return
	var boxed_in = (%LeftCast.is_colliding() && %RightCast.is_colliding()) \
			|| (!%FloorCastL.is_colliding() && !%FloorCastR.is_colliding())
	if boxed_in:
		flip_check() #blocked both ways: keep the cooldown so it can't flip every frame
	else:
		force_flip()

func refresh_casts():
	for cast in [%LeftCast, %RightCast, %FloorCastL, %FloorCastR]:
		cast.force_raycast_update()

func get_wall_hit_away_dir() -> Vector2:
	var side := 0.0 #local x side of the hit: -1 = left cast, +1 = right cast
	if %LeftCast.is_colliding(): side -= 1.0
	if %RightCast.is_colliding(): side += 1.0
	if side == 0.0: #both hit, go by travel direction
		side = sign(move_dir.rotated(-rotation).x)
	var wall_global = Vector2(side, 0.0).rotated(rotation)
	var away_x = -sign(wall_global.x)
	if abs(wall_global.x) < 0.5: #face away from the surface we were on
		away_x = -sign(wall_dir.x)
	return Vector2(away_x, 0.0)


func stop_all_timers():
	$IdleTimer.stop()
	$CrawlTimer.stop()
	$FleeTimer.stop()
	$AvoidTimer.stop()
	$LandTimer.stop()

### SIGNALS ###

func _on_IdleTimer_timeout():
	if player_in_detector:
		change_state("avoid")
	else:
		change_state("crawl")

func _on_CrawlTimer_timeout():
	change_state("idle")

func _on_FleeTimer_timeout():
	if player_in_detector: #flee again
		$FleeTimer.start(randf_range(flee_min_time, flee_max_time))
	else:
		change_state("crawl")

func _on_AvoidTimer_timeout():
	if player_in_detector: #avoid again
		$AvoidTimer.start(randf_range(flee_min_time, flee_max_time))
	else:
		change_state("crawl")

func _on_LandTimer_timeout():
	if state != "land" or dead: return
	var dir_x = sign(fall_land_dir.x)
	if dir_x == 0.0:
		dir_x = 1.0 if randf() < 0.5 else -1.0
	move_dir = Vector2(dir_x, 0.0)
	update_facing()
	if player_in_detector:
		change_state("avoid")
	else:
		change_state("crawl")

func _on_PlayerDetector_body_entered(body: Node2D):
	active_player = body.get_parent()
	player_in_detector = true
	if state in ["crawl", "idle"]:
		stop_all_timers()
		change_state("avoid")

func _on_PlayerDetector_body_exited(body: Node2D):
	if body.get_parent() == active_player:
		player_in_detector = false
