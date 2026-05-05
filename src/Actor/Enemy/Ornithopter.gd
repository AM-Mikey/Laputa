extends Enemy

const ICON = preload("res://assets/Actor/Enemy/OrnithopterIcon.png")

@export var dir = Vector2.LEFT
@export var difficulty: int = 0

var is_on_screen: bool = false
var has_swoop: bool = false

var swoop_speed: float = 120.0
var swoop_curve: Curve2D
var swoop_t: float
## The unit for all below constant is the distance of 1 cell in the grid
const min_swoop_detection_x: float = 5.0
const max_swoop_detection_x: float = 25.0
const min_swoop_height: float = 1.0
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
		1:
			hp = 3
			damage_on_contact = 2
			speed = Vector2(100, 100)
			acceleration = 25

			reward = 3

	if dir == Vector2.LEFT:
		$AnimationPlayer.play("FlyLeft")
		if (difficulty == 1):
			$VisibleOnScreenNotifier2D.position = Vector2(16.0, -3.0)
			#$PlayerDetection.target_position.x = -(swoop_distance - 1.0) * 16.0
			#$PlayerDetection.position = Vector2(-8.0, (swoop_height - 0.5) * 16.0)
	elif dir == Vector2.RIGHT:
		$AnimationPlayer.play("FlyRight")
		if (difficulty == 1):
			$VisibleOnScreenNotifier2D.position = Vector2(-22.0, -3.0)
			#$PlayerDetection.target_position.x = (swoop_distance - 1.0) * 16.0
			#$PlayerDetection.position = Vector2(8.0, (swoop_height - 0.5) * 16.0)
	change_state("fly")

func enter_fly(_prev_state):
	if dir == Vector2.LEFT:
		$AnimationPlayer.play("FlyLeft")
	elif dir == Vector2.RIGHT:
		$AnimationPlayer.play("FlyRight")

func do_fly(_delta):
	velocity = calc_velocity(dir, false)
	move_and_slide()

	if (difficulty == 1):
		var screen_size_x = (get_viewport().get_visible_rect().size / vs.resolution_scale).x
		var screen_too_thin_check = screen_size_x < 300.0
		if (screen_too_thin_check or (is_on_screen and !screen_too_thin_check)):
			var player = f.pc()
			if (player):
				var player_direction_check = sign(player.global_position.x - global_position.x) == sign(dir.x)
				var player_grid_coord = floor(player.global_position / 16.0)
				var grid_coord = floor(global_position / 16.0)
				var player_distance_relative = abs(player_grid_coord.x - grid_coord.x)
				var player_height_relative = player_grid_coord.y - grid_coord.y

				var valid_to_swoop = player_height_relative >= min_swoop_height and player_height_relative <= max_swoop_height  \
									and player_distance_relative >= min_swoop_detection_x and player_distance_relative <= min(max_swoop_detection_x, floor(screen_size_x / 16.0)) \
									and player_direction_check

				if (!has_swoop and valid_to_swoop):
					change_state("swoop")



func enter_swoop(_prev_state: String):
	var player = f.pc()
	if (!player or player.dead):
		change_state("fly")
		return

	var screen_size: Vector2 = get_viewport().get_visible_rect().size / vs.resolution_scale

	if dir == Vector2.LEFT:
		$AnimationPlayer.play("SwoopLeft")
	elif dir == Vector2.RIGHT:
		$AnimationPlayer.play("SwoopRight")
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

	am.play("ornithopter", self)

	if (debug):
		var points: PackedVector2Array = swoop_curve.tessellate_even_length(5, 5.0)
		$Debug.default_color = Color(randf(), randf(), randf())
		$Debug.points = points

func do_swoop(delta: float):
	swoop_t += swoop_speed * delta
	var curr_transform: Transform2D = swoop_curve.sample_baked_with_rotation(swoop_t)
	global_position = curr_transform.get_origin()
	#global_rotation = curr_transform.get_rotation()

	if (swoop_t > swoop_curve.get_baked_length()):
		change_state("fly")

func exit_swoop(_next_state: String):
	swoop_curve = null
	swoop_t = 0.0

func _on_VisibleOnScreenNotifier2d_screen_entered() -> void:
	is_on_screen = true

func _on_VisibleOnScreenNotifier2d_screen_exited() -> void:
	is_on_screen = false
