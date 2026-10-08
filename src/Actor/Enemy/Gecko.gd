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
var crawl_dir = Vector2.LEFT

var crawl_speed = Vector2(20, 20)
var flee_speed = Vector2(100, 100)
var idle_min_time = 1.0
var idle_max_time = 10.0
var crawl_min_time = 2.0
var crawl_max_time = 6.0
var flee_min_time = 1.0
var flee_max_time = 4.0
var flip_cooldown_time = 2.0

#TODO: dust particles for when running (ala minecraft cats)

#stands still, scurries away when player near, crawls slowly otherwise.
#drops off when hit?
#walks through ssps

func setup(): #Reminder: no function called can use await
	normal_dir = $NormalVector.direction
	wall_dir = normal_dir * -1
	crawl_dir.x = normal_dir.cross($CrawlVector.direction)
	$Sprite2D.scale.x = crawl_dir.x * -1
	rotation = normal_dir.angle() + deg_to_rad(90)
	gravity = 0
	move_dir = crawl_dir.rotated(rotation)


	hp = 2
	damage_on_contact = 2
	w.emit_signal("finished_spawn_entities_step")

	change_state("crawl")


func _on_physics_process(_delta):
	if disabled or dead or Engine.is_editor_hint(): return
	velocity = calc_velocity(move_dir, false) #no gravity
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

	#var player_collider = $CenteredPivot/PlayerCast.get_collider()
	#var world_collider = $CenteredPivot/WorldCast.get_collider()
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

func do_flee(_delta):
	# Prevent pixel gaps between the beetle and the terrain by making the beetle stick closer to the wall
	var collision := move_and_collide(wall_dir * 5, true)
	# The first move_and_collide doesn't move the body, instead it tests if the body *would* collide if moved
	if collision != null:
		if collision.get_travel().length() > 0.0001:
			move_and_collide(wall_dir * 5)
	#var player_collider = $CenteredPivot/PlayerCast.get_collider()
	#var world_collider = $CenteredPivot/WorldCast.get_collider()
	if !%FloorCastL.is_colliding() || !%FloorCastR.is_colliding(): #At edge
		flip_check()
	elif %LeftCast.is_colliding() || %RightCast.is_colliding(): #At wall
		flip_check()

func exit_flee(_next_state):
	if (!$FlipCooldown.is_stopped()):
		$FlipCooldown.stop()



func flip_check():
	if $FlipCooldown.is_stopped():
		$FlipCooldown.start(flip_cooldown_time)
		move_dir *= -1.0
		crawl_dir *= -1.0
		$Sprite2D.scale.x *= -1.0


func set_collision_shapes(shape_name):
	match shape_name:
		"crawl":
			$CollisionShape2D.disabled = false
			$Hurtbox/Crawl.disabled = false
			$Hitbox/Crawl.disabled = false
			$Fall.disabled = true
			$Hurtbox/Fall.disabled = true
			$Hitbox/Fall.disabled = true
		"fall":
			$CollisionShape2D.disabled = true
			$Hurtbox/Crawl.disabled = true
			$Hitbox/Crawl.disabled = true
			$Fall.disabled = false
			$Hurtbox/Fall.disabled = false
			$Hitbox/Fall.disabled = false

func _on_IdleTimer_timeout():
	change_state("crawl")

func _on_CrawlTimer_timeout():
	change_state("idle")

func _on_FleeTimer_timeout():
	change_state("crawl")
