extends Enemy

const ICON = preload("res://assets/Actor/Enemy/OrnithopterIcon.png")

const TX_0 = preload("res://assets/Actor/Enemy/Ornithopter.png")
const TX_1 = preload("res://assets/Actor/Enemy/Ornithopter1.png")

@export var dir := Vector2.LEFT
@export var difficulty := 0
var max_difficulty := 1

var is_on_screen: bool = false
var has_swoop: bool = false

var swoop_curve: Curve2D
var swoop_t: float
const swoop_speed: float = 120.0
const swoop_speed_thin: float = 90.0
const screen_thin_threshold_x: float = 250.0
## The unit for all below constant is the distance of 1 cell in the grid
@export var swoop_trigger_distance_max: float = 10.0
const swoop_trigger_distance_min: float = 2.0

const min_swoop_height: float = 2.0
const max_swoop_height: float = 20.0
const min_swoop_distance: float = 15.0
const max_swoop_distance: float = 30.0

func setup():
	match difficulty:
		0:
			hp = 3
			damage_on_contact = 2
			speed = Vector2(100, 100)
			acceleration = 25

			reward = 1
			$Sprite2D.texture = TX_0
		1:
			hp = 3
			damage_on_contact = 2
			speed = Vector2(100, 100)
			acceleration = 25

			reward = 2
			$Sprite2D.texture = TX_1

	if dir == Vector2.LEFT:
			$VisibleOnScreenNotifier2D.position = Vector2(16.0, -3.0)
	elif dir == Vector2.RIGHT:
			$VisibleOnScreenNotifier2D.position = Vector2(-22.0, -3.0)

	w.emit_signal("finished_spawn_entities_step")
	change_state("fly")



func enter_fly(_prev_state):
	$Hurtbox/Swoop.disabled = true
	$Hurtbox/Fly.disabled = false
	$Hitbox/Swoop.disabled = true
	$Hitbox/Fly.disabled = false
	if dir == Vector2.LEFT:
		$Sprite2D.flip_h = false
	elif dir == Vector2.RIGHT:
		$Sprite2D.flip_h = true

func do_fly(_delta):
	if not $AnimationPlayer.is_playing():
		$AnimationPlayer.play("Fly")

	velocity = calc_velocity(dir, false)
	move_and_slide()

	if (difficulty == 1):
		if is_on_screen:
			var player = f.pc()
			if (player):
				var player_direction_check = sign(player.global_position.x - global_position.x) == sign(dir.x)
				var player_grid_coord = floor(player.global_position / 16.0)
				var grid_coord = floor(global_position / 16.0)
				var player_distance_relative = abs(player_grid_coord.x - grid_coord.x)
				var player_height_relative = player_grid_coord.y - grid_coord.y

				var valid_to_swoop = player_height_relative >= min_swoop_height \
				and player_height_relative <= max_swoop_height \
				and player_distance_relative <= swoop_trigger_distance_max \
				and player_distance_relative >= swoop_trigger_distance_min \
				and player_direction_check

				if !has_swoop and valid_to_swoop:
					change_state("swoop")



func enter_swoop(_prev_state: String):
	var player = f.pc()
	if (!player or player.dead):
		change_state("fly")
		return

	var screen_size: Vector2 = get_viewport().get_visible_rect().size / vs.resolution_scale
	var screen_too_thin_check = screen_size.x < screen_thin_threshold_x

	$AnimationPlayer.play("SwoopDown")
	$Hurtbox/Fly.disabled = true
	$Hurtbox/Swoop.disabled = false
	$Hitbox/Fly.disabled = true
	$Hitbox/Swoop.disabled = false
	if dir == Vector2.LEFT:
		$Sprite2D.flip_h = false
	elif dir == Vector2.RIGHT:
		$Sprite2D.flip_h = true

	# Derive swoop geometry from actual player position
	var player_offset: Vector2 = player.global_position - global_position
	var swoop_distance: float = min(abs(floor(player_offset.x * 2.0 / 16.0)), max_swoop_distance)
	var swoop_height: float = floor(player.global_position.y / 16.0) - floor(global_position.y / 16.0) - 0.5 # Aim at gun level instead of feet
	var height_grid_offset: float = 16.0 - fmod(global_position.y, 16.0)

	# Bottom point lands on player X; exit point mirrors the same distance past them
	var bottom_pos: Vector2 = Vector2(player.global_position.x, global_position.y + swoop_height * 16.0 + height_grid_offset)
	var exit_pos: Vector2 = global_position + Vector2(player_offset.x * 2.0, 0.0)

	# Clamp exit point to screen bounds on thin screens (Maybe not, it curves so bizzarely)
	#if screen_too_thin_check:
		#var screen_rect: Rect2 = vs.get_screen_global_rect()
		#exit_pos.x = clamp(exit_pos.x, screen_rect.position.x, screen_rect.position.x + screen_rect.size.x)

	swoop_t = 0.0
	swoop_curve = Curve2D.new()


	var swoop_toward_inner: float = clamp(
		remap(swoop_distance / 2.0, 0.0, max_swoop_distance, 0.0, max_swoop_distance),
		0.0, max_swoop_distance
	) * clamp(swoop_distance / swoop_height, 0.33, 3.0)

	var swoop_toward_outer: float = swoop_distance * 2.0 if swoop_distance / swoop_height >= 1.0 \
								 else swoop_distance * swoop_distance / swoop_height
	var swoop_toward_height: float = swoop_height * 16.0
	swoop_curve.add_point(global_position, Vector2.ZERO, Vector2(swoop_toward_inner * dir.x, swoop_toward_height))
	swoop_curve.add_point(bottom_pos, Vector2(-swoop_toward_outer * dir.x, 0.0), Vector2(swoop_toward_outer * dir.x, 0.0))
	swoop_curve.add_point(exit_pos, Vector2(-swoop_toward_inner * dir.x, swoop_toward_height), Vector2.ZERO)

	has_swoop = true
	am.play("ornithopter", self, null, 1.0, 0.1)

	if debug:
		var points: PackedVector2Array = swoop_curve.tessellate_even_length(5, 5.0)
		$Debug.default_color = Color(randf(), randf(), randf())
		$Debug.points = points

func do_swoop(delta: float):
	var calc_speed: float = swoop_speed
	swoop_t += calc_speed * delta
	var curr_transform: Transform2D = swoop_curve.sample_baked_with_rotation(swoop_t)
	global_position = curr_transform.get_origin()

	if swoop_t > (swoop_curve.get_baked_length() / 2.0):
		if $AnimationPlayer.current_animation != "SwoopUp":
			$AnimationPlayer.play("SwoopUp")

	if swoop_t > swoop_curve.get_baked_length():
		change_state("fly")

func exit_swoop(_next_state: String):
	$AnimationPlayer.play("SwoopUpTransition")
	swoop_curve = null
	swoop_t = 0.0



### SIGNALS ###

func _on_VisibleOnScreenNotifier2d_screen_entered():
	is_on_screen = true

func _on_VisibleOnScreenNotifier2d_screen_exited():
	is_on_screen = false
