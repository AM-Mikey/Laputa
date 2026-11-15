extends Enemy

const ICON = preload("res://assets/Actor/Enemy/StalagtiteIcon.png")
const TX_0 = preload("res://assets/Actor/Enemy/Stalagtite.png")
const TX_1 = preload("res://assets/Actor/Enemy/Stalagtite1.png")
const TX_2 = preload("res://assets/Actor/Enemy/Stalagtite2.png")
const TOOLTIPS = [
"LV 0: Falls when player underneath. Becomes platform after landing.",
"LV 1: Falls when player underneath. Runs in random direction after landing.",
"LV 2: Falls when player underneath. Runs towards player after landing.",
]

var target: Node

var move_dir = Vector2.ZERO
@export var difficulty := 0
var max_difficulty := 2

var base_damage = 2
var drop_damage: int
var wait_time: float
var terminal_drop_velocity: float = 320.0

@export var land_impulse_curve: Curve

func set_is_in_water(val):
	if (state not in ["hang", "hangactive"]):
		super.set_is_in_water(val)
	is_in_water = val

func setup():
	match difficulty:
		0:
			hp = 2
			reward = 2
			drop_damage = 4
			wait_time = 0.5
			$Sprite2D.texture = TX_0
		1:
			hp = 2
			reward = 2
			drop_damage = 4
			wait_time = 0.5
			$Sprite2D.texture = TX_1
		2:
			hp = 3
			reward = 4
			drop_damage = 6
			wait_time = 0.1
			$Sprite2D.texture = TX_2
	damage_on_contact = base_damage
	enemy_damage_on_contact = 999
	safe_margin = 0.08
	speed = Vector2.ZERO
	gravity = 0
	w.emit_signal("finished_spawn_entities_step")

func link():
	change_state("hang")


func _on_physics_process(_delta):
	if state == "stake":
		velocity = Vector2.ZERO
	else:
		velocity = calc_velocity(move_dir)
	velocity.y = min(velocity.y, terminal_drop_velocity)
	set_up_direction(FLOOR_NORMAL)
	move_and_slide()
	_check_run_wall()


func enter_hang(_last_state):
	$AnimationPlayer.play("HangIdle")

func do_hang(_delta):
	var collider = $RayCast2D.get_collider()
	if collider:
		if collider is TileMapLayer: return
		if collider.get_collision_layer_value(1):
			target = collider.get_parent()
			change_state("hangactive")
			return


func enter_hangactive(_last_state):
	$AnimationPlayer.play("HangActive")
	$StateTimer.start(wait_time)


func enter_drop(_last_state):
	gravity = base_gravity if !is_in_water else water_gravity
	hit_enemies_on_contact = true
	damage_on_contact = drop_damage

func do_drop(_delta):
	if is_on_floor():
		if difficulty == 0: #purple
			change_state("stake")
			return
		else:
			change_state("squirm")
			return

func exit_drop(_next_state):
	hit_enemies_on_contact = false
	am.play("enemy_thud_0", self, null, 0.8, 0.1)
	land_impulse()

func enter_squirm(_last_state):
	$RayCast2D.queue_free()
	damage_on_contact = base_damage

	$CollisionShape2D.set_deferred("disabled", true)
	$GroundedCollision.set_deferred("disabled", false)

	move_dir = Vector2.ZERO
	if is_instance_valid(target):
		match difficulty:
			1:
				move_dir = Vector2(sign(global_position.x - target.global_position.x), 0) #opposite direction of player
			2:
				move_dir = Vector2(sign(target.global_position.x - global_position.x), 0) #direction of player
	if move_dir == Vector2.ZERO:
		#Randomize direction if no target exists or the player is exactly underneath
		move_dir = Vector2([-1.0, 1.0].pick_random(), 0)
	match move_dir:
		Vector2.LEFT: $Sprite2D.flip_h = false
		Vector2.RIGHT: $Sprite2D.flip_h = true
	$AnimationPlayer.play("Squirm")
	await $AnimationPlayer.animation_finished
	change_state("run")


func enter_run(_last_state):
	self_knockback = true
	speed = Vector2(100, 100)
	$AnimationPlayer.play("Run")
	$WallRight.enabled = true
	$WallLeft.enabled = true

func do_run(_delta):
	var ahead := _wall_ray(move_dir)
	var behind := _wall_ray(-move_dir)
	#only turn when the way back is open, otherwise stop
	if ahead && ahead.is_colliding() && !(behind && behind.is_colliding()):
		_turn_around()
	$Sprite2D.flip_h = move_dir == Vector2.RIGHT


func _check_run_wall():
	#catches obstacles the wall rays miss (low steps, corners)
	if state != "run" || !is_on_wall(): return
	var wall_normal := get_wall_normal()
	if sign(wall_normal.x) != -sign(move_dir.x): return # wall isn't in our movement direction
	var behind := _wall_ray(-move_dir)
	if behind && behind.is_colliding(): return
	_turn_around()


func _turn_around():
	move_dir = -move_dir
	$Sprite2D.flip_h = move_dir == Vector2.RIGHT


func _wall_ray(dir: Vector2) -> RayCast2D:
	match dir:
		Vector2.LEFT: return $WallLeft
		Vector2.RIGHT: return $WallRight
	return null


func exit_run(_next_state):
	$WallRight.enabled = false
	$WallLeft.enabled = false


func enter_stake(_last_state):
	$AnimationPlayer.play("Stake")
	am.play("enemy_stomp", self, null, 0.8, 0.1)
	stake_shake()
	await get_tree().process_frame
	$CollisionShape2D.set_deferred("disabled", true) #so it doesn't see itself
	$Standable/CollisionShape2D.set_deferred("disabled", false)

### HELPERS ###

func stake_shake():
	if f.pc():
		var player_distance = f.pc().global_position.distance_to(global_position)
		var max_distance := 512
		var max_shape_pixels := 4.0
		var shake_pixels = remap(player_distance, 0, max_distance, max_shape_pixels, 0.0)
		shake_pixels = clampf(shake_pixels, 0.0, max_shape_pixels)
		f.pc().get_node("PlayerCamera").shake(shake_pixels, 0.2, 4.0)

func land_impulse():
	if f.pc():
		var player_distance = f.pc().global_position.distance_to(global_position)
		var max_distance := 512
		var max_shape_pixels := 2.0
		var shake_pixels = remap(player_distance, 0, max_distance, max_shape_pixels, 0.0)
		shake_pixels = clampf(shake_pixels, 0.0, max_shape_pixels)
		f.pc().get_node("PlayerCamera").impulse(Vector2.DOWN, shake_pixels, 0.2, land_impulse_curve)

### SIGNALS ###

func _on_state_timer_timeout():
	if state == "hangactive":
		change_state("drop")
