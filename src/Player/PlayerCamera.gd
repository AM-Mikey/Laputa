extends Camera2D

var h_dir = -1
var homing_camera = false

@export var h_pan_min_speed = 0.5
@export var h_pan_time = 1.5
@export var v_pan_time = 1.5
@export var h_pan_delay = 0.0
@export var v_pan_delay = 0.0
@export var h_pan_distance = 2.0
@export var v_pan_distance = 2.0
@export var curve_elastic: Curve
#@export var control_overshoot_distance = 4.0

@onready var w = get_tree().get_root().get_node("World")
@onready var pc = get_parent()
@onready var mm = pc.get_node("MovementManager")
var h_tween: Tween
var v_tween: Tween
var control_tween: Tween
var control_return_tween: Tween

var adjusting_level_limits = false
var adjusted_limit_left: float
var adjusted_limit_right: float
var adjusted_limit_top: float
var adjusted_limit_bottom: float

var control_action_queue: Array[Array] = []
var control_active := false
var control_target: Node = null #reference to a node, not strictly necessary but saves performance

func _ready():
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)
	control_processing()

func _physics_process(_delta):
	#print("offset: ", offset, "limit left: ", limit_left)
	if !control_active: #regular camera
		if h_dir != pc.look_dir.x:
			h_dir = pc.look_dir.x
			pan_horizontal(pc.look_dir.x)

		if h_tween:
			if h_tween.is_running():
				h_tween.set_speed_scale(max(abs(pc.velocity.x)/mm.speed.x, h_pan_min_speed))

		if !pc.disabled and inp.can_act and !pc.mm.current_state == pc.mm.states["inspect"]:
			if inp.pressed("look_up",1) or inp.pressed("look_down",1) \
			or inp.released("look_up") or inp.released("look_down"):
				pan_vertical(get_v_dir())
	#else:
		#var ll = w.current_level.get_node("LevelLimiter")
		#on_limit_camera(ll.offset_left, ll.offset_right, ll.offset_top, ll.offset_bottom) #set limit every frame



### MAIN ###

func pan_vertical(dir):
	var dist = v_pan_distance / vs.resolution_scale
	if v_tween:
		v_tween.kill()
	v_tween = create_tween()
	v_tween.tween_property(self, "drag_vertical_offset", dir * dist, v_pan_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(v_pan_delay) #TODO: dir*dist here is technically incorrect since we just need a value between -1 and 1. this howevwer affects the speed, and it feels good as is now

func pan_horizontal(dir):
	var dist = h_pan_distance / vs.resolution_scale
	if h_tween:
		h_tween.kill()
	h_tween = create_tween()
	h_tween.tween_property(self, "drag_horizontal_offset", dir * dist, h_pan_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(h_pan_delay)

func stop_tweens():
	if h_tween: h_tween.kill()
	if v_tween: v_tween.kill()
	if control_tween: control_tween.kill()
	if control_return_tween: control_return_tween.kill()

func reset(): #TODO: REMOVE THESE AWAITS IT CAUSES SHIT TO MULTITHREAD
	position_smoothing_enabled = false #reset_smoothing() has issues
	drag_horizontal_offset =  pc.look_dir.x * (h_pan_distance / vs.resolution_scale) #initialize camera offset
	force_update_scroll()
	await get_tree().process_frame #godot quirk that this requires two frames
	await get_tree().process_frame
	position_smoothing_enabled = true



### MANUAL CONTROL

##						CAMERA CONTROL ACTION TYPES
##				goto_pos
##x[1] = positionX
##x[2] = positionY
##x[3]= speed
##				goto_player
##x[1] = speed
##				goto_waypoint
##x[1] = waypoint index
##x[2] = speed
##				wait
##x[1] = framecount
##				can_act
##x[1] = bool. Calling this locks the input until the last action or ['inputlock',false] is called.
##				reset
##instantly resets the camera back to player.
##
##future actions:
##goto_object. Uses the node directory in player's parent?


func control_processing():
	if control_action_queue.size() == 0: #just hold camera in place
		return
	print(control_action_queue)
	control_active = true
	var current_action = control_action_queue[0]
	match current_action[0]: #[0]= action name
		"to_pos":
			control_to_position(Vector2(current_action[1],current_action[2]),current_action[3])
		"to_player":
			control_to_player(current_action[1])
		"to_waypoint":
			control_to_waypoint(current_action[1],current_action[2])
		"wait":
			await get_tree().create_timer(current_action[1], false, true).timeout
			control_next()
		"hold":
			control_next(false) #go to the next one without running it
		"can_act":
			inp.can_act = current_action[1]
			control_next()
		"reset":
			control_reset()
			control_next()


func control_add(action: Array):
	control_action_queue.append(action)
	if !control_active || control_action_queue.size() == 1: #after a hold this will be active but the only index
		control_processing()


func control_next(with_processing = true, stop_on_queue_empty = true): #remove the current action
	control_target = null
	control_action_queue.pop_front()
	if !with_processing:
		return
	if stop_on_queue_empty && control_action_queue.size() == 0:
		control_stop()
	else:
		control_processing()


func control_stop(): #return to automatic camera
	control_active = false
	inp.can_act = true
	control_reset()
	adjusting_level_limits = false
	var ll = w.current_level.get_node("LevelLimiter") #to reset the limits
	on_limit_camera(ll.offset_left, ll.offset_right, ll.offset_top, ll.offset_bottom)


func control_to_position(target_pos: Vector2, speed: float, do_player_drag_offset = false):
	stop_tweens()
	if w.dll.get_node("DialogBox"):
		w.dll.get_node("DialogBox").busy = true
	var overshoot_dist = (target_pos - global_position).length() / 64.0
	var overshoot_pos = target_pos + overshoot_dist * global_position.direction_to(target_pos)
	var limited_overshoot_pos = limit_pos(target_pos) + overshoot_dist * global_position.direction_to(target_pos)

	position_smoothing_enabled = false
	drag_vertical_offset = 0
	drag_horizontal_offset = 0

	global_position = get_target_position()
	limit_enabled = false

	control_tween = create_tween()
	if limit_pos(target_pos) != target_pos: #target is outside limits
		var drag_time = (limit_pos(target_pos) - global_position).length() / (speed * 16.0)
		control_tween.tween_property(self, "global_position", limited_overshoot_pos, drag_time * 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		await control_tween.finished
		control_return_tween = create_tween()
		control_return_tween.tween_property(self, "global_position", limit_pos(target_pos), drag_time * 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		var drag_time = (target_pos - global_position).length() / (speed * 16.0)
		control_tween.tween_property(self, "global_position", overshoot_pos, drag_time * 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		await control_tween.finished
		control_return_tween = create_tween()
		control_return_tween.tween_property(self, "global_position", target_pos, drag_time * 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	await control_return_tween.finished
	print("mhm")
	limit_enabled = true
	position_smoothing_enabled = true

	if w.dll.get_node("DialogBox"):
		w.dll.get_node("DialogBox").busy = false
	control_next(true, false)


func limit_pos(pos) -> Vector2:
	var vp_size = get_viewport_rect().size / zoom
	var vp_center = vp_size / 2.0
	var min_x = limit_left + vp_center.x
	var max_x = limit_right - vp_center.x
	var min_y = limit_top + vp_center.y
	var max_y = limit_bottom - vp_center.y

	# Guard against limits narrower than the viewport (would invert min/max)
	if min_x > max_x:
		var mid_x = (limit_left + limit_right) / 2.0
		min_x = mid_x
		max_x = mid_x
	if min_y > max_y:
		var mid_y = (limit_top + limit_bottom) / 2.0
		min_y = mid_y
		max_y = mid_y

	return Vector2(
		clamp(pos.x, min_x, max_x),
		clamp(pos.y, min_y, max_y))


func control_to_player(speed: float): #Moves camera towards player position
	var player_pos: Vector2 = pc.global_position + Vector2(0, -16)
	await control_to_position(player_pos, speed, true)
	if control_action_queue.size() == 0: #since there's no more in the queue, returning to the player ends manual control
		control_stop()


func control_to_waypoint(waypoint_index: int, speed: float):
	var waypoints := get_tree().get_nodes_in_group("WaypointGlobals")
	var target_pos := Vector2(0, 0)
	if control_target == null:
		for node in waypoints:
			if node.index == waypoint_index:
				control_target = node
		if control_target == null:
			printerr("ERROR: WAYPOINT GLOBAL NOT FOUND")
	target_pos = control_target.global_position
	control_to_position(target_pos, speed)


func control_reset(): #resets camera back to player instantly
	position = Vector2(0, -16)
	reset()

### HELPERS ###

#func trend_float_to_zero(input_float: float, speed: float) -> float:
	#var result:float = input_float
	#if input_float > 0:
		#result = max(0, input_float - speed)
	#if input_float < 0:
		#result = min(0, input_float + speed)
	#return result



### GETTERS ###

func get_v_dir() -> int:
	var dir = 0
	if inp.can_act:
		if inp.held("look_up"): dir -= 1
		if inp.held("look_down"): dir += 1
	return dir



### TRIGGERS ###

func on_limit_camera(left, right, top, bottom):
	if adjusting_level_limits:
		left = adjusted_limit_left
		right = adjusted_limit_right
		top = adjusted_limit_top
		bottom = adjusted_limit_bottom
	var window_width = get_window().get_size().x
	var window_height = get_window().get_size().y

	if window_width > (right - left) * vs.resolution_scale:
		#print("WARNING: window width larger than camera limit")
		var thickness = ((window_width / vs.resolution_scale) - (right - left))/2

		limit_left = left - thickness
		limit_right = right + thickness
	else:
		limit_left = left
		limit_right = right

	if (get_window().get_size().y > (bottom - top) * vs.resolution_scale):
		#print("WARNING: window height larger than camera limit")
		var thickness = (window_height / vs.resolution_scale - (bottom - top))/2

		limit_top = top - thickness
		limit_bottom = bottom + thickness
	else:
		limit_top = top
		limit_bottom = bottom

### SIGNALS ###

func _resolution_scale_changed(resolution_scale):
	zoom = Vector2(resolution_scale, resolution_scale)
	reset()
