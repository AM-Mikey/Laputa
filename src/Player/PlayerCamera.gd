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
@export var control_overshoot_distance = 2.0

@onready var w = get_tree().get_root().get_node("World")
@onready var pc = get_parent()
@onready var mm = pc.get_node("MovementManager")
var h_tween: Tween
var v_tween: Tween
var control_tween: Tween
var limit_tween_left: Tween
var limit_tween_right: Tween
var limit_tween_top: Tween
var limit_tween_bottom: Tween

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
	if limit_tween_left: limit_tween_left.kill()
	if limit_tween_right: limit_tween_right.kill()
	if limit_tween_top: limit_tween_top.kill()
	if limit_tween_bottom: limit_tween_bottom.kill()

func reset():
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
	#Keep last position until we call a reset or to player
	if control_action_queue.size() == 0: return
	#print(control_action_queue)
	control_active = true
	var current_action = control_action_queue[0]
	match current_action[0]: #[0]= action name
		"to_pos":
			control_to_position(Vector2(current_action[1],current_action[2]),current_action[3])
		"to_player":
			await control_to_player(current_action[1])
			if control_action_queue.size() == 0:
				print("mom")
				control_stop()
		"to_waypoint":
			control_to_waypoint(current_action[1],current_action[2])
		"wait":
			await get_tree().create_timer(current_action[1], false, true).timeout
			control_next()
			if control_action_queue.size() == 0:
				control_stop()
		"hold":
			control_next(false) #go to the next one without running it
		"can_act":
			inp.can_act = current_action[1]
			control_next()
			if control_action_queue.size() == 0:
					control_stop()
		"reset":
			control_reset()
			control_next()
			if control_action_queue.size() == 0:
				control_stop()


func control_add(action: Array):
	control_action_queue.append(action)
	if !control_active || control_action_queue.size() == 1: #after a hold this will be active but the only index
		control_processing()


func control_next(with_processing = true): #remove the current action
	control_target = null
	control_action_queue.pop_front()
	if with_processing:
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
	w.dll.get_node("DialogBox").busy = true
	var target_offset = target_pos - global_position
	var start_offset = offset
	var overshoot_target = target_offset + (target_offset - start_offset).normalized() * control_overshoot_distance
	var drag_time = (target_offset - start_offset).length() / (speed * 16.0)

	h_tween = create_tween()
	v_tween = create_tween()
	if !do_player_drag_offset:
		h_tween.tween_property(self, "drag_horizontal_offset", 0.0, drag_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		v_tween.tween_property(self, "drag_vertical_offset", 0.0, drag_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		var dist = h_pan_distance / vs.resolution_scale
		h_tween.tween_property(self, "drag_horizontal_offset", pc.look_dir.x * dist, drag_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		v_tween.tween_property(self, "drag_vertical_offset", 0.0, drag_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	control_tween = create_tween()
	#move to slightly past target
	control_tween.tween_property(self, "offset", overshoot_target, drag_time * 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	#settle back to exact target
	control_tween.tween_property(self, "offset", target_offset, drag_time * 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	limit_tween_left = create_tween()
	limit_tween_right = create_tween()
	limit_tween_top = create_tween()
	limit_tween_bottom = create_tween()
	if !do_player_drag_offset:
		adjusting_level_limits = true
		adjusted_limit_left = limit_left - target_offset.x
		limit_tween_left.tween_property(self, "limit_left", adjusted_limit_left, drag_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		adjusted_limit_right = limit_right - target_offset.x
		limit_tween_right.tween_property(self, "limit_right", adjusted_limit_right, drag_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		adjusted_limit_top = limit_top - target_offset.y
		limit_tween_top.tween_property(self, "limit_top", adjusted_limit_top, drag_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		adjusted_limit_bottom = limit_bottom - target_offset.y
		limit_tween_bottom.tween_property(self, "limit_bottom", adjusted_limit_bottom, drag_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	else:
		adjusting_level_limits = false
		var ll = w.current_level.get_node("LevelLimiter") #to reset the limits
		limit_tween_left.tween_property(self, "limit_left", ll.offset_left, drag_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		limit_tween_right.tween_property(self, "limit_right", ll.offset_right, drag_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		limit_tween_top.tween_property(self, "limit_top", ll.offset_top, drag_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		limit_tween_bottom.tween_property(self, "limit_bottom", ll.offset_bottom, drag_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	await control_tween.finished
	w.dll.get_node("DialogBox").busy = false
	control_next()

func control_to_player(speed: float): #Moves camera towards player position
	var player_pos: Vector2 = pc.global_position + Vector2(0.001, -15.999)
	control_to_position(player_pos, speed, true)


func control_to_waypoint(waypoint_index: int, speed: float):
	var waypoints := get_tree().get_nodes_in_group("Waypoints")
	var target_pos := Vector2(0, 0)
	if control_target == null:
		for node in waypoints:
			if node.index == waypoint_index:
				control_target = node
		if control_target == null:
			printerr("ERROR: WAYPOINT NOT FOUND")
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
