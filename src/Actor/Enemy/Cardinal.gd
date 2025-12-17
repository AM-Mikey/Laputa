extends Enemy

var target

var move_dir = Vector2.ZERO
var look_dir = Vector2.LEFT

var waypoints = {}
@export var start_waypoint_id := 0
var current_waypoint_id = start_waypoint_id
var waypoint_tolerance := 2.0

@export var max_speed := Vector2(150.0, 100.0)

func setup():
	change_state("idle")
	reward = 1
	hp = 1
	set_floor_stop_on_slope_enabled(true)
	find_waypoints()

func find_waypoints():
	for wp in get_tree().get_nodes_in_group("Waypoints"):
		if wp.owner_id == id:
			waypoints[wp.index] = wp




func _on_physics_process(_delta):
	if disabled or dead: return
	velocity = calc_velocity(move_dir)
	move_and_slide()
	animate()

### STATES ###

func enter_flee(_last_state):
	current_waypoint_id += 1
	if current_waypoint_id >= waypoints.size():
		current_waypoint_id = 0

func do_flee():
	var distance_from_waypoint = waypoints[current_waypoint_id].global_position - global_position
	move_dir = distance_from_waypoint.normalized()
	look_dir = move_dir
	speed = Vector2( \
	min(8.0 * abs(distance_from_waypoint.x), max_speed.x), \
	min(8.0 * abs(distance_from_waypoint.y), max_speed.y))

	if waypoint_tolerance >= abs(distance_from_waypoint.x) and waypoint_tolerance >= abs(distance_from_waypoint.y):
		move_dir = Vector2.ZERO
		change_state("idle")


### SFX ###

func tweet():
	am.play("enemy_tweet", self)


func animate():
	$Sprite2D.flip_h = true if look_dir.x > 0.0 else false
	if state == "idle":
		$AnimationPlayer.play("Idle")
	if state == "flee":
			$AnimationPlayer.play("Fly", -1, (velocity.x / max_speed.x))

### SIGNALS ###

func _on_PlayerDetector_body_entered(body):
	target = body.owner
	if state == "idle":
		change_state("flee")

func _on_PlayerDetector_body_exited(_body):
	target = null
