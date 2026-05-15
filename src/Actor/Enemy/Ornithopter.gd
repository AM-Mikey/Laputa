extends Enemy

const ICON = preload("res://assets/Actor/Enemy/OrnithopterIcon.png")

const TX_0 = preload("res://assets/Actor/Enemy/Ornithopter.png")
const TX_1 = preload("res://assets/Actor/Enemy/Ornithopter1.png")

@export var dir = Vector2.LEFT
@export var difficulty: int = 0
var max_difficulty := 1

var is_on_screen: bool = false
var has_swoop: bool = false

var swoop_curve: Curve2D
var swoop_t: float
const swoop_speed: float = 120.0
const swoop_speed_thin: float = 90.0
const screen_thin_threshold_x: float = 250.0
## The unit for all below constant is the distance of 1 cell in the grid
const min_swoop_detection_x: float = 5.0
const max_swoop_detection_x: float = 25.0
const max_swoop_detection_x_thin: float = 15.0

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

			reward = 2
			$Sprite2D.texture = TX_0
		1:
			hp = 3
			damage_on_contact = 2
			speed = Vector2(100, 100)
			acceleration = 25

			reward = 3
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
	if not $AnimationPlayer.is_playing(): #wait for transition
		$AnimationPlayer.play("Fly")

	velocity = calc_velocity(dir, false)
	move_and_slide()

	if (difficulty == 1):
		var screen_size = vs.get_screen_global_rect().size
		var screen_too_thin_check = screen_size.x < screen_thin_threshold_x
		if screen_too_thin_check or (is_on_screen and !screen_too_thin_check):
			var player = f.pc()
			if (player):
				var player_direction_check = sign(player.global_position.x - global_position.x) == sign(dir.x)
				var player_grid_coord = floor(player.global_position / 16.0)
				var grid_coord = floor(global_position / 16.0)
				var player_distance_relative = abs(player_grid_coord.x - grid_coord.x)
				var player_height_relative = player_grid_coord.y - grid_coord.y

				var max_check_distance =  min(max_swoop_detection_x, floor(screen_size.x / 16.0)) if !screen_too_thin_check else max_swoop_detection_x_thin

				var valid_to_swoop = player_height_relative >= min_swoop_height and player_height_relative <= min(max_swoop_height, floor(screen_size.y / 16.0 / 2.0))  \
									and player_distance_relative >= min_swoop_detection_x and player_distance_relative <= max_check_distance \
									and player_direction_check

				if (!has_swoop and valid_to_swoop):
					change_state("swoop")



func enter_swoop(_prev_state: String):
	var player = f.pc()
	if (!player or player.dead):
		change_state("fly")
		return

	var screen_size: Vector2 = get_viewport().get_visible_rect().size / vs.resolution_scale

	$AnimationPlayer.play("SwoopDown")
	$Hurtbox/Fly.disabled = true
	$Hurtbox/Swoop.disabled = false
	$Hitbox/Fly.disabled = true
	$Hitbox/Swoop.disabled = false
	if dir == Vector2.LEFT:
		$Sprite2D.flip_h = false
	elif dir == Vector2.RIGHT:
		$Sprite2D.flip_h = true
	var height_grid_offset = 16.0 - fmod(global_position.y, 16.0)
	var swoop_height = floor(player.global_position.y / 16.0) - floor(global_position.y / 16.0) - 0.5 # Aim at gun level instead of feet
	var swoop_distance = clamp(floor(screen_size.x * clamp(remap(screen_size.x, 300.0, 500.0, 1.0, 0.8), 1.0, 0.8) / 16.0), min_swoop_distance, max_swoop_distance)
	swoop_t = 0.0
	swoop_curve = Curve2D.new()
	var swoop_toward_inner: float = clamp(remap(screen_size.x, min_swoop_distance * 16.0, max_swoop_distance * 16.0, 0.0, max_swoop_distance * 8.0), 0.0, max_swoop_distance / 8.0) * clamp(swoop_distance / swoop_height, 1.0, 3.0)
	var swoop_toward_outer: float = swoop_distance * 2.0
	var swoop_toward_height: float = swoop_height * 16.0
	swoop_curve.add_point(global_position, Vector2.ZERO, Vector2(swoop_toward_inner * dir.x, swoop_toward_height))
	swoop_curve.add_point(global_position + Vector2(dir.x * swoop_distance * 8.0, swoop_height * 16.0 + height_grid_offset), Vector2(-swoop_toward_outer * dir.x, 0.0), Vector2(swoop_toward_outer * dir.x, 0.0))
	swoop_curve.add_point(global_position + Vector2(dir.x * swoop_distance * 16.0, 0), Vector2(-swoop_toward_inner * dir.x, swoop_toward_height), Vector2.ZERO)
	has_swoop = true

	am.play("ornithopter", self, null, 1.0, 0.1)

	if debug:
		var points: PackedVector2Array = swoop_curve.tessellate_even_length(5, 5.0)
		$Debug.default_color = Color(randf(), randf(), randf())
		$Debug.points = points

func do_swoop(delta: float):
	var calc_speed: float = swoop_speed_thin if vs.get_screen_global_rect().size.x < screen_thin_threshold_x else swoop_speed
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
