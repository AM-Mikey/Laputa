extends Enemy

const WAYPOINT = preload("res://src/Utility/Waypoint.tscn") #TODO: clean up waypoint implementation to match NPC

@export var move_dir = Vector2.ZERO
@export var flap_time = 0.1
@export var idle_time = 0.05
var can_flap = false

var waypoints = {}
@export var start_waypoint := 0
var aggro_waypoint = null
var current_waypoint := 0
var target_tolerance = 2

var starting_state = "idle"
var aggro = false
var bail_time = 6.0


@onready var target: Node
@onready var target_pos = position
@onready var ap = $AnimationPlayer



func setup():
	change_state(starting_state)
	hp = 4
	reward = 2
	damage_on_contact = 2
	speed = Vector2(100, 50)
	find_waypoints()

func find_waypoints():
	for w in get_tree().get_nodes_in_group("Waypoints"):
		if w.owner_id == id and w.index != -1: #dont include the aggro waypoint
			waypoints[w.index] = w
	if not waypoints.is_empty():
		set_target(start_waypoint)


func set_target(index: int):
	if target != null:
		target.deactivate()
	if index == -1:
		target = aggro_waypoint
	else:
		target = waypoints[index]
	target.activate()
	target_pos = target.position
	$BailTimer.start(bail_time)


func _on_physics_process(_delta):
	if disabled or dead: return
	velocity = calc_velocity(velocity, move_dir, speed)
	set_up_direction(FLOOR_NORMAL)
	move_and_slide()

	if aggro:
		var player_from_self = pc.position - position
		$RayCast2D.target_position = player_from_self

		if $RayCast2D.get_collider() == null:
			if aggro_waypoint:
				aggro_waypoint.queue_free()
				aggro_waypoint = null
			var waypoint = WAYPOINT.instantiate()
			waypoint.position = position + player_from_self #world pos of raycast
			waypoint.owner_id = id
			waypoint.index = -1
			world.current_level.add_child(waypoint)
			aggro_waypoint = waypoint
			set_target(-1)


	if target:
		if abs(target_pos.x - position.x) < target_tolerance and abs(target_pos.y - position.y) < target_tolerance:
			if not waypoints.is_empty(): #no target
				set_target(get_next_index(target.index))


func get_next_index(last_index) -> int:
	var next_index

	if last_index == -1:
		aggro_waypoint.queue_free()
		aggro_waypoint = null
		next_index = start_waypoint

	else: #normal
		var indexes = waypoints.keys()
		var array_pos = indexes.find(last_index)
		if array_pos != indexes.size() - 1: #not last position in array
			next_index = indexes[array_pos + 1]
		else:
			next_index = indexes.front()

	return next_index


### STATES ###

func enter_idle(_last_state):
	can_flap = false
	#this isnt the best way to do this, but returns a good result.
	#right now this cuts off move_dir when it's more than a block away (to -1 or 1)
	#the small adjustment when less than that is why we don't just use sign()
	var x_dir: float = clamp((target_pos.x - position.x)/16.0, -1.0, 1.0)
	move_dir = Vector2(lerp(move_dir.x, x_dir, 0.2), 0)

	$Sprite2D.flip_h = x_dir > 0
	if (aggro_waypoint):
		ap.play("UnflapAggro")
	else:
		ap.play("Unflap")
	await get_tree().create_timer(idle_time).timeout
	can_flap = true

func do_idle():
	if can_flap and position.y > target_pos.y: #lower than target
		change_state("flap")
		return
	if is_on_floor():
		change_state("flap")
		return

func enter_flap(_last_state):
	#this isnt the best way to do this, but returns a good result.
	var x_dir: float = clamp((target_pos.x - position.x)/16.0, -1.0, 1.0)
	move_dir = Vector2(lerp(move_dir.x, x_dir, 0.2), -1)

	$Sprite2D.flip_h = x_dir > 0
	if (aggro_waypoint):
		ap.play("FlapAggro")
	else:
		ap.play("Flap")
	await get_tree().create_timer(flap_time).timeout
	change_state("idle")


### SIGNALS ###

func _on_PlayerDetector_body_entered(_body):
	aggro = true
	$RayCast2D.enabled = true

func _on_PlayerDetector_body_exited(body):
	aggro = false
	$RayCast2D.enabled = false


func _on_BailTimer_timeout():
	if disabled: return
	if waypoints.is_empty(): #no target
		aggro_waypoint.queue_free()
		aggro_waypoint = null
	else:
		set_target(get_next_index(target.index))
