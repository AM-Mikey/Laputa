@icon("res://assets/Icon/NPCIcon.png") #TODO: redo all these scenes as basenpc
extends Actor
class_name NPC

const DB = preload("res://src/Dialog/DialogBox.tscn")
const STATE_LABEL = preload("res://src/Utility/StateLabel.tscn")

var state: String #TODO: make npc states, player states and enemy states work the same
@export var starting_state := "idle"
var cached_state: String
var predialog_state: String

var dialog_box: Node
var dialog_step: int = 1
var branch: String = ""

var active_pc = null
var disabled = false
var move_dir = Vector2.LEFT
var just_spawned = true

var waypoints = {}
#var current_waypoint := 0
var target_tolerance = 1
var target_waypoint: Node
var target_pos = null
var bail_time = 6.0
@export var walk_speed = Vector2(50, 50)

@export var id: String
@export_file("*.json") var dialog_json: String
@export var conversation: String
@export var voiced = true


var camera_forgiveness = 16

#@onready var pc = get_tree().get_root().get_node_or_null("World/Juniper")

func _ready():
	home = global_position
	find_waypoints()

	speed = Vector2.ZERO

	setup_states()
	change_state(starting_state)
	await get_tree().physics_frame
	await get_tree().physics_frame
	just_spawned = false



func disable():
	disabled = true

func enable():
	disabled = false

func _physics_process(_delta):
	if disabled: return
	if state != "":
		do_state()

	velocity = calc_velocity()
	move_and_slide()


func change_animation(animation: String): #, random_start = false): TODO: random start doesnt work with discrete animations because we could randomly start inbetween changing frames, thus keeping the old animation going until we hit a keyframe
	if animation == $AnimationPlayer.current_animation:
		return
	if not $AnimationPlayer.has_animation(animation):
		print("WARNING: animation: " + animation + " not found on npc with name: " + name)

	var start_time = 0
	#if random_start:
		#rng.randomize()
		#start_time = rng.randf_range(0, $AnimationPlayer.current_animation_length)

	$AnimationPlayer.play(animation, start_time)



### STATE MACHINE ###

func setup_states():
	var timer = Timer.new()
	timer.one_shot = true
	timer.name = "StateTimer"
	add_child(timer)

	var label = STATE_LABEL.instantiate()
	label.text = state
	label.name = "StateLabel"
	add_child(label)

func do_state():
	var do_method = "do_" + state
	if has_method(do_method):
		call(do_method)

func change_state(new):
	var last_state = state
	var next_state = new
	if state:
		var exit_method = "exit_" + state
		if has_method(exit_method):
			call(exit_method, next_state)
	state = new
	$StateLabel.text = state
	var enter_method = "enter_" + state
	if has_method(enter_method):
		call(enter_method, last_state)


### STATES ###
#func do_idle():
	#if target_waypoint:
		#change_state("walkto")


func do_walkto():
	change_animation("Walk")
	speed = walk_speed
	var tx = target_waypoint.global_position.x
	move_dir = Vector2(sign(tx - global_position.x), 0)
	$Sprite2D.flip_h = true if move_dir.x > 0 else false #set sprite to move_dir
	if abs(tx - global_position.x) < target_tolerance:
		speed = Vector2.ZERO
		if dialog_box:
			dialog_box.busy = false
		change_state(cached_state)
		return


func enter_walk(_last_state):
	change_animation("Walk")
	speed = walk_speed
	if not $FloorL.is_colliding() and move_dir.x < 0:
		move_dir = Vector2.RIGHT
	if not $FloorR.is_colliding() and move_dir.x > 0:
		move_dir = Vector2.LEFT
	rng.randomize()
	$StateTimer.start(rng.randf_range(1.0, 10.0))
	await $StateTimer.timeout
	if state == "walk":
		change_state("wait")
	return

func do_walk():
	$Sprite2D.flip_h = true if move_dir.x > 0 else false #set sprite to move_dir

	if (not $FloorL.is_colliding() and move_dir.x < 0) \
	or (not $FloorR.is_colliding() and move_dir.x > 0):
		change_state("wait")
		return
	if ($WallLB.is_colliding() || $WallLT.is_colliding()) and move_dir.x < 0 \
	or ($WallRB.is_colliding() || $WallRT.is_colliding()) and move_dir.x > 0:
		$Sprite2D.flip_h = !$Sprite2D.flip_h
		move_dir.x = move_dir.x * -1.0
		change_state("wait")
		return


func enter_wait(_last_state):
	change_animation("Idle")
	speed = Vector2.ZERO
	rng.randomize()
	$StateTimer.start(rng.randf_range(1.0, 5.0))
	await $StateTimer.timeout
	if state == "wait":
		change_state("walk")
	return


func enter_talk():
	if $AnimationPlayer.has_animation("Talk"):
		change_animation("Talk")
	else:
		change_animation("Idle")
	speed = Vector2.ZERO
	look_at_node(f.pc())

	f.pc().inspect_target = self
	if get_tree().get_nodes_in_group("DialogBoxes") != []:
		pass
	else:
		dialog_box = DB.instantiate()
		dialog_box.connect("dialog_finished", Callable(self, "on_dialog_finished"))
		get_tree().get_root().get_node("World/UILayer/UIGroup").add_child(dialog_box)
		dialog_box.start_printing(dialog_json, conversation)


### MISC

func _input(event):
	if event.is_action_pressed("inspect") and active_pc \
	and dialog_json != "" and conversation != "" and state != "talk" and active_pc.mm.current_state == active_pc.mm.states["run"]:
		if active_pc.can_input:
			predialog_state = state
			change_state("talk")
			return


func look_at_node(node):
	var look_dir = sign(node.global_position.x - global_position.x)
	$Sprite2D.flip_h = look_dir == 1


func calc_velocity(do_gravity = true) -> Vector2:
	var out: = velocity
	var fractional_speed = speed
	if is_in_water:
		fractional_speed = speed * Vector2(0.666, 0.666)
	out.x = fractional_speed.x * move_dir.x
	if do_gravity:
		out.y += gravity * get_physics_process_delta_time()
		if move_dir.y < 0:
			out.y = fractional_speed.y * move_dir.y
	else:
		out.y = fractional_speed.y * move_dir.y
	return out



### NEW PATHFINDING

func find_waypoints():
	for w in get_tree().get_nodes_in_group("Waypoints"):
		if w.owner_id.to_lower() == id.to_lower():
			waypoints[w.index] = w
	if not waypoints.is_empty():
		set_target(waypoints[0])

func set_target(new_target):
	if target_waypoint != null:
		target_waypoint.deactivate()
	target_waypoint = new_target
	target_waypoint.activate()
	$WaypointBailTimer.start(bail_time)

func get_next_waypoint() -> Node:
	return(waypoints[(target_waypoint.index + 1) % waypoints.size()])

func walk_to_waypoint(index):
	set_target(waypoints[index])
	cached_state = "talk"
	if dialog_box:
		dialog_box.busy = true
	change_state("walkto")
	return



### SIGNALS

func _on_PlayerDetector_body_entered(body):
	active_pc = body.owner

func _on_PlayerDetector_body_exited(_body):
	active_pc = null

func _on_waypoint_bail_timer_timeout(): #TODO: consider reimplementing (ala child.tscn)
	pass
	#if disabled or waypoints.is_empty(): return
	#set_target(get_next_waypoint())

func on_dialog_finished():
	change_state(predialog_state)
