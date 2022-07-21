extends Enemy


export var move_dir = Vector2.ZERO
export var flap_time = 0.1
export var idle_time = 0.05
var can_flap = false

var waypoints = {}
var current_waypoint := 0
var target_tolerance = 2

onready var target: Node
onready var target_pos = position

func _ready():
	change_state("idle")
	hp = 4
	reward = 2
	damage_on_contact = 2
	speed = Vector2(100, 50)
	yield(get_tree(), "idle_frame")
	find_waypoints()


func find_waypoints():
	for w in get_tree().get_nodes_in_group("Waypoints"):
		print("pwpadkw")
		if w.owner_id == id:
			waypoints[w.index] = w
	set_target(0)


func set_target(index: int):
	if target != null:
		target.deactivate()
	target = waypoints[index]
	target.activate()
	target_pos = target.position


func _physics_process(_delta):
	if disabled or dead: return
	#target_pos = w.get_global_mouse_position()
	velocity = get_custom_velocity(velocity, move_dir, speed)
	velocity = move_and_slide(velocity, FLOOR_NORMAL)
	
	if target:
		if abs(target_pos.x - position.x) < target_tolerance and abs(target_pos.y - position.y) < target_tolerance:
			set_target(get_next_index(target.index))


func get_next_index(last_index) -> int:
	var next_index
	
	var indexes = waypoints.keys()
	var array_pos = indexes.find(last_index)
	if array_pos != indexes.size() - 1: #not last position in array
		next_index = indexes[array_pos + 1]
	else:
		next_index = indexes.front()
	
	return next_index


func enter_idle():
	can_flap = false
	var x_dir = clamp((target_pos.x - position.x)/16, -1, 1)

#	if abs(target_pos.x - position.x) < 16: #at target
#		x_dir = lerp(x_dir, 0, 0.2)

	move_dir = Vector2(lerp(move_dir.x, x_dir, 0.2), 0)
		
	$Sprite.flip_h = x_dir > 0
	$AnimationPlayer.play("Unflap")
	yield(get_tree().create_timer(idle_time), "timeout")
	can_flap = true

func do_idle():
	if can_flap and position.y > target_pos.y: #lower than target
		change_state("flap")
	if is_on_floor():
		change_state("flap")

func enter_flap():
	var x_dir = clamp((target_pos.x - position.x)/16, -1, 1)
	
#	if abs(target_pos.x - position.x) < 16: #at target
#		x_dir = lerp(x_dir, 0, 0.2)
		
	move_dir = Vector2(lerp(move_dir.x, x_dir, 0.2), -1)
		
	$Sprite.flip_h = x_dir > 0
	$AnimationPlayer.play("Flap")
	yield(get_tree().create_timer(flap_time), "timeout")
	change_state("idle")



func get_custom_velocity(velocity: Vector2, move_dir, speed, do_gravity = true) -> Vector2:
	var out: = velocity
	out.x = speed.x * move_dir.x
	if do_gravity:
		out.y += gravity * get_physics_process_delta_time()
		if move_dir.y < 0:
			out.y = speed.y * move_dir.y
	else:
		out.y = speed.y * move_dir.y
		
	return out
