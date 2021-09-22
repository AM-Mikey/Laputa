extends Enemy

#const SNAP_DIRECTION = Vector2.DOWN
#const SNAP_LENGTH = 4.0
#var snap_vector = SNAP_DIRECTION * SNAP_LENGTH

export var starting_direction = Vector2.LEFT
var move_dir: Vector2
var ground_dir: Vector2


var look_dir: Vector2
var waiting = false
export var wait_time = 1.0

export var climb_dir = "cw"


var did_air_frame = false

func _ready():
	hp = 4
	damage_on_contact = 2
	speed = Vector2(60, 60)
	move_dir = starting_direction
	look_dir = starting_direction
	acceleration = 25
	
	level = 3
	
#	$RayCast2D.cast_to = Vector2(200, 200) * starting_direction #cast ray left or right 200 px

func _physics_process(_delta):
	if climb_dir == "cw":
		if is_on_floor() and not is_on_wall() and not is_on_ceiling():
			move_dir = Vector2.LEFT
			ground_dir = Vector2.DOWN
			#print("is on floor")
		elif is_on_ceiling() and not is_on_floor() and not is_on_wall():
			#print("is on ceil")
			move_dir = Vector2.RIGHT
			ground_dir = Vector2.UP
		elif is_on_wall() and not is_on_floor() and not is_on_ceiling():
			#print("is on wall")
			if get_which_wall_collided() == "left":
				#print("wall is left")
				move_dir = Vector2.UP
				ground_dir = Vector2.LEFT
			if get_which_wall_collided() == "right":
				#print("wall is right")
				move_dir = Vector2.DOWN
				ground_dir = Vector2.RIGHT
		
		elif is_on_floor() and is_on_wall():
			#print("on floor and wall")
			move_dir = Vector2.UP
			ground_dir = Vector2.LEFT
		
		elif is_on_ceiling() and is_on_wall():
			#print("on ceiling and wall")
			move_dir = Vector2.DOWN
			ground_dir = Vector2.RIGHT


		else: #if they hit air, meaning the platform goes down from their perspective
			#print("is in air")
			var old_ground_dir = ground_dir
			match old_ground_dir:
				Vector2.LEFT:
					ground_dir = Vector2.DOWN
					move_dir = Vector2.LEFT
				Vector2.RIGHT:
					ground_dir = Vector2.UP
					move_dir = Vector2.RIGHT
				Vector2.UP:
					ground_dir = Vector2.LEFT
					move_dir = Vector2.UP
				Vector2.DOWN:
					ground_dir = Vector2.RIGHT
					move_dir = Vector2.DOWN

	#snap_vector = ground_dir * SNAP_LENGTH
	velocity = calculate_movevelocity(velocity, move_dir, ground_dir, speed)
	move_and_slide(velocity, FLOOR_NORMAL)
	#move_and_slide_with_snap(velocity, snap_vector, FLOOR_NORMAL, true)
	
	animate()

func get_which_wall_collided():
	for i in range(get_slide_count()):
		var collision = get_slide_collision(i)
		if collision.normal.x > 0:
			return "left"
		elif collision.normal.x < 0:
			return "right"
	return "none"

func calculate_movevelocity(
		linearvelocity: Vector2,
		move_dir: Vector2,
		ground_dir: Vector2,
		speed: Vector2
		) -> Vector2:
	
	var out: = linearvelocity
	var gravity_vector = ground_dir * gravity

	out.x = speed.x * move_dir.x
	out.y = speed.y * move_dir.y
	out += gravity_vector
	
	return out
	
func animate():
	match ground_dir:
		Vector2.LEFT:
			if move_dir == Vector2.UP:
				$AnimationPlayer.play("ClingLeftCrawlUp")
			if move_dir == Vector2.DOWN:
				$AnimationPlayer.play("ClingLeftCrawlDown")
		Vector2.RIGHT:
			if move_dir == Vector2.UP:
				$AnimationPlayer.play("ClingRightCrawlUp")
			if move_dir == Vector2.DOWN:
				$AnimationPlayer.play("ClingRightCrawlDown")
		Vector2.UP:
			if move_dir == Vector2.LEFT:
				$AnimationPlayer.play("ClingUpCrawlLeft")
			if move_dir == Vector2.RIGHT:
				$AnimationPlayer.play("ClingUpCrawlRight")
		Vector2.DOWN:
			if move_dir == Vector2.LEFT:
				$AnimationPlayer.play("ClingDownCrawlLeft")
			if move_dir == Vector2.RIGHT:
				$AnimationPlayer.play("ClingDownCrawlRight")

