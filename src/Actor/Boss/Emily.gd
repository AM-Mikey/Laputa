extends Boss

var max_x_speed = 100
var jump_speed = 100


export var idle_time = .5


var move_dir = Vector2.ZERO
var target_position


var step = 1
var max_step = 1

#states
var active_state: String
signal idle


func _ready():
	display_name = "Emily"
	hp = 25
	max_hp = hp
	damage_on_contact = 2
	ground_cof = 0.2
	air_cof = 0.05
	
	acceleration = 50
	
	emit_signal("setup_ui", display_name, hp, max_hp)
	
	loop()




func loop():
	while hp > 0:
		walk(Vector2.LEFT, 6)
		yield(self, "idle")
		yield(get_tree().create_timer(0.4), "timeout")
		
		walk(Vector2.RIGHT, 6)
		yield(self, "idle")
		yield(get_tree().create_timer(0.4), "timeout")
		
		charge(Vector2.LEFT)
		yield(self, "idle")
		yield(get_tree().create_timer(0.4), "timeout")
		
		charge(Vector2.RIGHT)
		yield(self, "idle")
		yield(get_tree().create_timer(0.4), "timeout")


func walk(dir, dist):
	print("walking")
	move_dir = dir
	target_position = Vector2(global_position.x + (((dist * 16 ) -8) * dir.x), global_position.y)
	active_state = "walk"

func charge(dir):
	print("charging")
	move_dir = dir
	yield(get_tree().create_timer(0.1), "timeout") #wait before declaring active state, so process doesn't catch the charge at 0 velocity
	active_state = "charge"

func stop():
	print("stopping")
	move_dir = Vector2.ZERO
	active_state = "idle"
	emit_signal("idle")
	


func jump(dir, dist, height):
	active_state = "jump"
	move_dir = Vector2(dir.x, -1)
	#max_x_speed = 13.5 * dist
	#jump_speed = (27.25 + 73.7 / height) * height
	jump_speed = (23.5 * height) + 88.9
	print(jump_speed)
	
	target_position = Vector2(global_position.x + (((dist * 16 ) -8) * dir.x), global_position.y)


func _physics_process(delta):
	if not is_on_floor():
		move_dir.y = 0
	
	match active_state:
		"walk":
			match move_dir:
				Vector2.LEFT: 
					if global_position.x <= target_position.x:
						stop()
				Vector2.RIGHT:
					if global_position.x >= target_position.x:
						stop()
		"charge":
			if abs(velocity.x) < 0.1:
				stop()
		
	
	velocity = calculate_movevelocity(velocity, move_dir)
	velocity = move_and_slide(velocity, FLOOR_NORMAL, true)




func calculate_movevelocity(linearvelocity: Vector2, move_dir) -> Vector2:
	var out = linearvelocity
	
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
