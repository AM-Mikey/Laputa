extends Enemy

const WAYPOINT = preload("res://src/Utility/Waypoint.tscn")

export var move_dir = Vector2.ZERO
export var flap_time = 0.1
export var idle_time = 0.05
var can_flap = false

var waypoints = {}
export var start_waypoint := 0
var current_waypoint := 0
var target_tolerance = 2

var aggro = false
#var dive_range = 100
var bail_time = 6.0


onready var target: Node
onready var target_pos = position
onready var ap = $AnimationPlayer

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
		if w.owner_id == id:
			waypoints[w.index] = w
	set_target(start_waypoint)


func set_target(index: int):
	if target != null:
		target.deactivate()
	target = waypoints[index]
	target.activate()
	target_pos = target.position
	$BailTimer.start(bail_time)


func _physics_process(_delta):
	if disabled or dead: return
	#target_pos = w.get_global_mouse_position()
	velocity = get_custom_velocity(velocity, move_dir, speed)
	velocity = move_and_slide(velocity, FLOOR_NORMAL)
	
	if aggro:
		var player_from_self = pc.position - position
#		var magnatude = sqrt(pow(player_from_self.x, 2) + pow(player_from_self.y, 2))
#		var normalized = player_from_self / magnatude #magnatude = 1
#		var scalar = normalized * dive_range
		$RayCast2D.cast_to = player_from_self
		
		if $RayCast2D.get_collider() == null:
			for w in get_tree().get_nodes_in_group("Waypoints"):
				if w.owner_id == id and w.index == -1:
					w.queue_free()
			var waypoint = WAYPOINT.instance()
			waypoint.position = position + player_from_self #world pos of raycast
#			waypoint.owner_id = id #TODO: breaks if we have no id
#			waypoint.index = -1
			world.current_level.add_child(waypoint)
			waypoints[-1] = waypoint
			set_target(-1)
			
	
	if target:
		if abs(target_pos.x - position.x) < target_tolerance and abs(target_pos.y - position.y) < target_tolerance:
			set_target(get_next_index(target.index))


func get_next_index(last_index) -> int:
	var next_index
	
	if waypoints.has(-1):
		waypoints[-1].queue_free()
		waypoints.erase(-1) #get rid of aggro waypoint here
	
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
	ap.play("UnflapAggro") if waypoints.has(-1) else ap.play("Unflap")
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
	ap.play("FlapAggro") if waypoints.has(-1) else ap.play("Flap")
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



func _on_PlayerDetector_body_entered(body):
	aggro = true
	$RayCast2D.enabled = true

func _on_PlayerDetector_body_exited(body):
	aggro = false
	$RayCast2D.enabled = false


func _on_BailTimer_timeout():
	set_target(get_next_index(target.index))
