extends Enemy

var target: Node

export var look_dir: Vector2 = Vector2.LEFT
var move_dir: Vector2 = Vector2.UP #start moving upwards constantly

var panic_run = false
var touchdown = false

export var base_damage = 2
export var falling_damage = 6

func _ready():
	hp = 4
	damage_on_contact = base_damage
	speed = Vector2(100, 100)

func _physics_process(delta):
	if not dead:
		_velocity = calculate_move_velocity(_velocity, move_dir, speed)
		_velocity = move_and_slide(_velocity, FLOOR_NORMAL)
		
		if panic_run == true:
			if is_on_floor() and touchdown == false: #check to see if they've landed before
				touchdown = true
				move_dir.x = look_dir.x
				yield(get_tree().create_timer(0.1), "timeout") #delay to change damage back to base
				damage_on_contact = base_damage
			if is_on_wall():
				move_dir.x *= -1


func calculate_move_velocity(_velocity: Vector2, move_dir, speed) -> Vector2:
	var out: = _velocity
	
	out.x = speed.x * move_dir.x
	out.y += gravity * get_physics_process_delta_time()
	if move_dir.y < 0:
		out.y = speed.y * move_dir.y

	return out
	
	
	
func _on_PlayerDetector_body_entered(body):
	if visible == true:
		target = body
		drop()

func drop():
	$PlayerDetector.set_deferred("monitoring", false) #no longer needs to be triggered
	move_dir.y = 0 #fall
	panic_run = true
	damage_on_contact = falling_damage
	#var height_from_target = global_position.y - target.global_position.y
