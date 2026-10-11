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
var fall_drift_speed := 40.0
var land_time := 0.3


#TODO: dust particles for when running (ala minecraft cats)

#stands still, scurries away when player near, crawls slowly otherwise.
#drops off when hit?
#walks through ssps

func setup(): #Reminder: no function called can use await
	normal_dir = $NormalVector.direction
	wall_dir = normal_dir * -1
	var crawl_dir = Vector2(normal_dir.cross($CrawlVector.direction), 0)
	$Sprite2D.scale.x = crawl_dir.x * -1
	rotation = normal_dir.angle() + deg_to_rad(90)
	gravity = 0.0
	move_dir = crawl_dir.rotated(rotation)

	hp = 2
	damage_on_contact = 2
	w.emit_signal("finished_spawn_entities_step")

	change_state("crawl")


func _on_physics_process(_delta):
	if disabled or dead or Engine.is_editor_hint(): return
	velocity = calc_velocity(move_dir, true)
	move_and_slide()


func enter_idle(_delta):
	$AnimationPlayer.play("Crawl")
	speed = Vector2.ZERO
	$IdleTimer.start(randf_range(idle_min_time, idle_max_time))


func enter_crawl(_last_state):
	$AnimationPlayer.play("Crawl")
	speed = crawl_speed
	set_collision_shapes("crawl")
	$CrawlTimer.start(randf_range(crawl_min_time, crawl_max_time))

func do_crawl(_delta):
	# Prevent pixel gaps between the beetle and the terrain by making the beetle stick closer to the wall
	var collision := move_and_collide(wall_dir * 5, true)
	# The first move_and_collide doesn't move the body, instead it tests if the body *would* collide if moved
	if collision != null:
		if collision.get_travel().length() > 0.0001:
			move_and_collide(wall_dir * 5)

	if !%FloorCastL.is_colliding() || !%FloorCastR.is_colliding(): #At edge
		flip_check()
	elif %LeftCast.is_colliding() || %RightCast.is_colliding(): #At wall
		flip_check()

func exit_crawl(_next_state):
	if (!$FlipCooldown.is_stopped()):
		$FlipCooldown.stop()


func enter_flee(_last_state):
	$AnimationPlayer.play("Crawl")
	speed = flee_speed
	set_collision_shapes("crawl")
	$FleeTimer.start(randf_range(flee_min_time, flee_max_time))
	if wall_dir.y == 0.0: #wall
		move_dir.y *= -1.0
	if wall_dir.x == 0.0: #floor/ceiling
		move_dir.x *= -1.0

func do_flee(_delta):
	# Prevent pixel gaps between the beetle and the terrain by making the beetle stick closer to the wall
	var collision := move_and_collide(wall_dir * 5, true)
	# The first move_and_collide doesn't move the body, instead it tests if the body *would* collide if moved
	if collision != null:
		if collision.get_travel().length() > 0.0001:
			move_and_collide(wall_dir * 5)

	if !%FloorCastL.is_colliding() && !%FloorCastR.is_colliding(): #past edge
		var drift = Vector2(sign(move_dir.x), 0.0)
		fall_land_dir = drift
		fall_drift_dir = drift
		stop_all_timers()
		change_state("fall")
	elif %LeftCast.is_colliding() || %RightCast.is_colliding(): #At wall
		if is_on_floor_surface():
			flip_check()
		else:
			var away = get_wall_hit_away_dir()
			fall_land_dir = away
			fall_drift_dir = away
			stop_all_timers()
			change_state("fall")

func exit_flee(_next_state):
	if (!$FlipCooldown.is_stopped()):
		$FlipCooldown.stop()


func enter_fall(_last_state):
	$AnimationPlayer.play("Idle")
	fall_time = 0.0
	#turn upright
	normal_dir = Vector2.UP
	wall_dir = Vector2.DOWN
	rotation = 0.0
	gravity = base_gravity #TODO: not accounting for water gravity, just sets to 90
	velocity = Vector2.ZERO
	move_dir = fall_drift_dir
	speed = Vector2(fall_drift_speed, fall_drift_speed)
	set_collision_shapes("fall")

func do_fall(delta):
	fall_time += delta
	if is_on_floor():
		gravity = 0.0
		change_state("land")


func enter_land(_last_state):
	$AnimationPlayer.play("Idle")
	speed = Vector2.ZERO
	move_dir = Vector2.ZERO
	velocity = Vector2.ZERO
	$LandTimer.start(land_time)



func enter_avoid(_last_state):
	$AnimationPlayer.play("Crawl")
	speed = avoid_speed
	set_collision_shapes("crawl")
	$AvoidTimer.start(randf_range(avoid_min_time, avoid_max_time))


func do_avoid(_delta):
	# Prevent pixel gaps between the beetle and the terrain by making the beetle stick closer to the wall
	var collision := move_and_collide(wall_dir * 5, true)
	# The first move_and_collide doesn't move the body, instead it tests if the body *would* collide if moved
	if collision != null:
		if collision.get_travel().length() > 0.0001:
			move_and_collide(wall_dir * 5)

	var local_dir_to_player = (active_player.global_position - global_position).rotated(-global_rotation)
	var away_x = -sign(local_dir_to_player.x)
	if away_x != 0.0:
		move_dir = Vector2(away_x, 0.0).rotated(global_rotation)
		$Sprite2D.scale.x = -away_x # same facing convention as setup(): local +x => scale.x = -1

	if !%FloorCastL.is_colliding() || !%FloorCastR.is_colliding(): #At edge
		flip_check()
		await get_tree().physics_frame #wait for flip
		if player_in_detector:
			stop_all_timers()
			change_state("flee")
		else:
			stop_all_timers()
			change_state("crawl")
	elif %LeftCast.is_colliding() || %RightCast.is_colliding(): #At wall
		flip_check()
		await get_tree().physics_frame #wait for flip
		if player_in_detector:
			stop_all_timers()
			change_state("flee")
		else:
			stop_all_timers()
			change_state("crawl")


func exit_avoid(_next_state):
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
		print("flip")
		$FlipCooldown.start(flip_cooldown_time)
		move_dir *= -1.0
		$Sprite2D.scale.x *= -1.0
		#$Hurtbox/Crawl.position.x =

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

func set_collision_shapes(shape_name):
	match shape_name:
		"crawl":
			$CollisionShape2D.set_deferred("disabled", false)
			$Hurtbox/Crawl.set_deferred("disabled", false)
			$Hitbox/Crawl.set_deferred("disabled", false)
			$Fall.set_deferred("disabled", true)
			$Hurtbox/Fall.set_deferred("disabled", true)
			$Hitbox/Fall.set_deferred("disabled", true)
		"fall":
			$CollisionShape2D.set_deferred("disabled", true)
			$Hurtbox/Crawl.set_deferred("disabled", true)
			$Hitbox/Crawl.set_deferred("disabled", true)
			$Fall.set_deferred("disabled", false)
			$Hurtbox/Fall.set_deferred("disabled", false)
			$Hitbox/Fall.set_deferred("disabled", false)

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
	$Sprite2D.scale.x = -dir_x #same facing convention as setup()
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
