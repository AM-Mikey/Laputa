extends Boss

var max_x_speed = 100
var jump_speed = 100


export var idle_time = .5


var move_dir = Vector2.ZERO
var target_position

var active_state: String
var idle = true
var step = 1
var max_step = 1


func _ready():
	display_name = "Emily"
	hp = 25
	max_hp = hp
	damage_on_contact = 2
	ground_cof = 0.2
	air_cof = 0.05
	
	acceleration = 50
	
	emit_signal("setup_ui", display_name, hp, max_hp)


func walk(dir, dist):
	active_state = "walk"
	move_dir = dir
	target_position = Vector2(global_position.x + (((dist * 16 ) -8) * dir.x), global_position.y)



func jump(dir, dist, height):
	active_state = "jump"
	move_dir = Vector2(dir.x, -1)
	#max_x_speed = 13.5 * dist
	#jump_speed = (27.25 + 73.7 / height) * height
	jump_speed = (23.5 * height) + 88.9
	print(jump_speed)
	
	target_position = Vector2(global_position.x + (((dist * 16 ) -8) * dir.x), global_position.y)



func _process(delta):
	if idle == true:
		idle = false
		yield(get_tree().create_timer(idle_time), "timeout")
		if step == 1:
			#walk(Vector2.LEFT, 6)
			jump(Vector2.LEFT, 10, 3)
			
		if step == 2:
			#walk(Vector2.RIGHT, 6)
			pass
		if step == 3:
			pass
		
		#if step == max_step:
			#step = 1
		#else:
		step +=1


func _physics_process(delta):
	if not is_on_floor():
		move_dir.y = 0
	
	_velocity = calculate_move_velocity(_velocity, move_dir)
	_velocity = move_and_slide(_velocity, FLOOR_NORMAL, true)
	
	
	
	if move_dir == Vector2.LEFT:
		if global_position.x <= target_position.x:
			print("stopping")
			move_dir = Vector2.ZERO
			idle = true

	if move_dir == Vector2.RIGHT:
		if global_position.x >= target_position.x:
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
