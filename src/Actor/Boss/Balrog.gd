extends Boss

var max_x_speed = 100
var jump_speed = 100
var acceleration = 50
export var ground_cof = 0.2
export var air_cof = 0.05


var move_dir = Vector2.ZERO
var target_position
var idle = true

func _ready():
	hp = 25
	damage_on_contact = 2
	
	walk(Vector2.LEFT, 5)


func walk(dir, dist):
	move_dir = dir
	target_position = Vector2(global_position.x + (dist * 16 * dir.x), global_position.y)
	print(global_position)
	print(target_position)


func _physics_process(delta):
	_velocity = calculate_move_velocity(_velocity, move_dir)
	_velocity = move_and_slide(_velocity, FLOOR_NORMAL, true)
	
	
	
	if move_dir == Vector2.LEFT:
		print("ok")
		if global_position.x <= target_position.x:
			print("stopping")
			
			move_dir = Vector2.ZERO
			idle = true


func calculate_move_velocity(linear_velocity: Vector2, move_dir) -> Vector2:
	var out = linear_velocity
	
	var friction = false
	
	out.y += gravity * get_physics_process_delta_time()
	if move_dir.y < 0:
		out.y = jump_speed * move_dir.y
	#if is_jump_interrupted:
	#	out.y = 0.0
	
	if move_dir.x != 0:
		out.x = min(abs(out.x) + acceleration, max_x_speed)
		out.x *= move_dir.x
	else:
		friction = true
		
	
	
	if is_on_floor():
		if friction == true:
			out.x = lerp(out.x, 0, ground_cof)
	else:
		if friction == true:
			out.x = lerp(out.x, 0, air_cof)
		
	return out
