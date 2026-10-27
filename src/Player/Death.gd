extends Node

@onready var w = get_tree().get_root().get_node("World")
@onready var pc = get_parent().get_parent().get_parent()
@onready var mm = pc.get_node("MovementManager")
@onready var sprite = pc.get_node("Sprite2D")
@onready var guns = pc.get_node("GunManager/Guns")
@onready var ap = pc.get_node("AnimationPlayer")

const LAUNCH_MULT := Vector2(2.0, 2.0) #scales mm.knockback_speed for the death launch
const BOUNCE_DAMPING := 0.5 #fraction of vertical impact speed kept after each bounce
const BOUNCE_X_DAMPING := 0.7 #fraction of horizontal speed kept after each floor bounce
const WALL_DAMPING := 0.5
const MIN_BOUNCE_SPEED := 40.0 #below this vertical speed we stop bouncing and land
const MAX_BOUNCES := 3
const BAIL_TIME := 4.0

var die_via_kill_box = false
var facing := "front"
var bounces := 0
var landed := false
var death_screen_displayed = false
var bailing = false

func state_process(_delta):
	if bailing: return
	pc.velocity = calc_velocity()
	var pre_velocity = pc.velocity
	pc.move_and_slide()

	if !landed:
		if pc.is_on_wall():
			pc.velocity.x = -pre_velocity.x * WALL_DAMPING
		if pc.is_on_floor() && pre_velocity.y > 0.0:
			var bounce_speed = pre_velocity.y * BOUNCE_DAMPING
			if bounces < MAX_BOUNCES && bounce_speed >= MIN_BOUNCE_SPEED:
				bounces += 1
				pc.velocity.y = -bounce_speed
				pc.velocity.x = pre_velocity.x * BOUNCE_X_DAMPING
				am.play("pc_land")
			else: #out of bounces, settle on the ground
				landed = true
				pc.velocity.y = 0.0
				mm.snap_vector = mm.SNAP_DIRECTION * mm.SNAP_LENGTH
	elif !death_screen_displayed:
		death_screen_displayed = true
		w.ui.add_child(load("res://src/UI/DeathScreen/DeathScreen.tscn").instantiate())

	animate()


func bail(do_explosion = true):
	bailing = true
	pc.velocity = Vector2.ZERO
	pc.visible = false
	if do_explosion:
		var explosion = pc.EXPLOSION.instantiate()
		explosion.position = pc.global_position
		w.middle_front.add_child(explosion)
	death_screen_displayed = true
	w.ui.add_child(load("res://src/UI/DeathScreen/DeathScreen.tscn").instantiate())


func set_move_dir():
	var move_dir = Vector2.ZERO
	if inp.can_act:
		move_dir = Vector2(inp.analogstick.x, 0.0)
		if !mm.coyote_timer.is_stopped() && Input.is_action_just_pressed("jump"):
			move_dir = Vector2(move_dir.x, -1.0)
	pc.move_dir = move_dir



func animate():
	var next_animation: String
	var reference_texture = preload("res://assets/Player/Death.png")
	match facing:
		"front":
			if landed:
				next_animation = "death_front"
			elif bounces >= 1:
				next_animation = "death_mid_front"
			else:
				next_animation = "death_fall_front"
		"back":
			if landed:
				next_animation = "death_back"
			elif bounces >= 1:
				next_animation = "death_mid_back"
			else:
				next_animation = "death_fall_back"

	#for runtime, set the frame counts before the animation starts
	sprite.hframes = int(reference_texture.get_width() / 32.0)
	sprite.vframes = int(reference_texture.get_height() / 32.0)

	var vframe = get_vframe()
	sprite.frame_coords.y = vframe

	if !ap.is_playing() || ap.current_animation != next_animation:
		ap.stop()
		ap.play(next_animation)

func get_vframe() -> int:
	var out = 0
	match pc.look_dir.x:
		-1: out = 0
		1: out = 1
	return out


#### GETTERS ###

func calc_velocity():
	var out = pc.velocity
	#Y
	out.y += mm.gravity * get_physics_process_delta_time()
	out.y = min(mm.terminal_velocity, out.y)
	#X
	if landed: #ground friction slide
		out.x = lerp(out.x, 0.0, mm.ground_cof)
	else: #air friction slide
		out.x = lerp(out.x, 0.0, mm.air_cof)
	if abs(out.x) < mm.min_x_velocity: #clamp velocity
		out.x = 0
	return out


func get_launch_velocity() -> Vector2:
	var dir: Vector2 = mm.knockback_direction
	if dir == Vector2.ZERO: #no hit direction (e.g. fell out of the world), launch away from where we're looking
		dir = Vector2(-pc.look_dir.x, 0.0)
	if dir.length() <= 1.0:
		return Vector2(mm.knockback_speed.x * dir.x * LAUNCH_MULT.x, -mm.knockback_speed.y * LAUNCH_MULT.y)
	else: #large knockback vectors are used as-is, but always upwards
		return Vector2(dir.x, -abs(dir.y) if dir.y != 0.0 else -mm.knockback_speed.y * LAUNCH_MULT.y)

### STATE ###

func enter(_prev_state: String):
	if die_via_kill_box:
		print("awye")
		bail(false)
		return


	var disable = [
		pc.get_node("CollisionShape2D"),
		pc.get_node("CrouchingCollision")]
	var enable = [
		pc.get_node("JumpCollision")]
	mm.disable_collision_shapes(disable)
	mm.enable_collision_shapes(enable)

	pc.set_up_direction(mm.FLOOR_NORMAL)
	pc.set_floor_stop_on_slope_enabled(true)

	mm.snap_vector = Vector2.ZERO

	guns.visible = false
	bounces = 0
	landed = false

	mm.knockback_velocity = get_launch_velocity()
	pc.velocity = mm.knockback_velocity
	facing = "front" if sign(pc.velocity.x) == sign(pc.look_dir.x) or pc.velocity.x == 0.0 else "back"

	await get_tree().create_timer(BAIL_TIME).timeout
	if !death_screen_displayed:
		bail()


func exit(_next_state: String):
	pass
