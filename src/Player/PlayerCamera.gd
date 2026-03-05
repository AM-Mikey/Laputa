extends Camera2D

const BLACKBAR = preload("res://src/Utility/BlackBar.tscn")

var h_dir = -1
var homing_camera = false

@export var h_pan_min_speed = 0.5
@export var h_pan_time = 1.5
@export var v_pan_time = 1.5
@export var h_pan_delay = 0.0
@export var v_pan_delay = 0.0
@export var h_pan_distance = 2.0
@export var v_pan_distance = 2.0

@onready var w = get_tree().get_root().get_node("World")
@onready var pc = get_parent()
@onready var mm = pc.get_node("MovementManager")
var h_tween: Tween
var v_tween: Tween

func _ready():
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)


func _physics_process(_delta):
	cameracontrol_processing()

	if not cameracontrol_active: #regular camera
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
	v_tween.tween_property(self, "drag_vertical_offset", dir * dist, v_pan_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(v_pan_delay)

func pan_horizontal(dir):
	var dist = h_pan_distance / vs.resolution_scale
	if h_tween:
		h_tween.kill()
	h_tween = create_tween()
	h_tween.tween_property(self, "drag_horizontal_offset", dir * dist, h_pan_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(h_pan_delay)

func stop_tween():
	h_tween.kill()
	v_tween.kill()

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
var cameracontrol_actions:Array[Array] =[

	]

var cameracontrol_active := false
var cameracontrol_target:Node = null #reference to a node, not strictly necessary but saves performance

func cameracontrol_processing() -> void:
	if Input.is_action_just_pressed("debug_testbutton"):
		cameracontrol_add(['can_act',false] )
		cameracontrol_add( ['goto_waypoint',0,16] )
		cameracontrol_add( ['wait',20] )
		cameracontrol_add( ['goto_waypoint',1,8] )
		cameracontrol_add( ['wait',20] )

	##Terminate cameracontrol related code if no actions remain
	if len(cameracontrol_actions) == 0:
		if cameracontrol_active == true:
			cameracontrol_active = false
			inp.can_act = true
			manual_reset()
		return
	##Camera control code
	else:
		print (cameracontrol_actions)
		cameracontrol_active = true
		var current_action = cameracontrol_actions[0]
		match current_action[0]: #[0]= action name
			"goto_pos":
				manual_to_position(Vector2(current_action[1],current_action[2]),current_action[3])
			"goto_player":
				manual_to_player(current_action[1])
			"goto_waypoint":
				manual_to_waypoint(current_action[1],current_action[2])
			"wait":
				if current_action[1] > 0:
					current_action[1] -= 1 #decrement happens inside the action instead of a dedicated timer
					drag_horizontal_offset = trend_float_to_zero(drag_horizontal_offset,0.08)

				else:
					cameracontrol_next()
			"can_act":
				inp.can_act = current_action[1]
				cameracontrol_next()
			"reset":
				manual_reset()
				cameracontrol_next()


func cameracontrol_add(action:Array) -> void:
	cameracontrol_actions.append(action)

##Removes the current action
func cameracontrol_next() -> void:
	cameracontrol_target = null
	cameracontrol_actions.pop_at(0)

func manual_to_position(target_pos: Vector2, speed: float):
	if h_tween:
		h_tween.kill()
	if v_tween:
		v_tween.kill()
	var drag_speed = min(speed/200,0.2)
	drag_horizontal_offset = trend_float_to_zero(drag_horizontal_offset,drag_speed)
	drag_vertical_offset = trend_float_to_zero(drag_vertical_offset,drag_speed)

	var pos_delta := target_pos - global_position
	var movement := pos_delta.normalized() * speed
	if global_position.distance_to(target_pos) <= global_position.distance_to(global_position + movement):
		global_position = target_pos
		cameracontrol_next() #end
	else:
		global_position += movement

func manual_reset(): #resets camera back to player instantly
	position = Vector2(0,-16)
	reset()

func manual_to_player(speed: float): #Moves camera towards player position
	if h_tween:
		h_tween.kill()
	if v_tween:
		v_tween.kill()
	var drag_speed = min(speed/200,0.2)
	drag_horizontal_offset = trend_float_to_zero(drag_horizontal_offset,drag_speed)
	drag_vertical_offset = trend_float_to_zero(drag_vertical_offset,drag_speed)

	var target_pos: Vector2 = pc.position
	var pos_delta := target_pos - global_position
	var movement := pos_delta.normalized() * speed
	if global_position.distance_to(target_pos) <= global_position.distance_to(global_position + movement):
		global_position = target_pos
		cameracontrol_next() #end
	else:
		global_position += movement

func manual_to_waypoint(waypoint_index:int,speed:float) -> void:
	var waypoints := get_tree().get_nodes_in_group("Waypoints")
	var target_pos := Vector2(0,0)
	if cameracontrol_target == null:
		for node in waypoints:
			if node.index == waypoint_index:
				cameracontrol_target = node
		if cameracontrol_target == null:
			print ("WAYPOINT NOT FOUND!!!!!")
	target_pos = cameracontrol_target.position
	manual_to_position(target_pos,speed)




func trend_float_to_zero(input_float:float, speed:float) -> float:
	var result:float = input_float
	if input_float > 0:
		result = max(0, input_float - speed)
	if input_float < 0:
		result = min(0, input_float + speed)
	return result



### GETTERS ###

func get_v_dir() -> int:
	var dir = 0
	if inp.can_act:
		if inp.held("look_up"): dir -= 1
		if inp.held("look_down"): dir += 1
	return dir



### TRIGGERS ###

func on_limit_camera(left, right, top, bottom):
	var window_width = get_window().get_size().x
	var window_height = get_window().get_size().y

	for b in get_tree().get_nodes_in_group("BlackBars"):
		b.free()

	if window_width > (right - left) * vs.resolution_scale:
		#print("WARNING: window width larger than camera limit")
		var thickness = ((window_width / vs.resolution_scale) - (right - left))/2

		spawn_black_bar("BarLeft", \
		Vector2(thickness + 1, window_height), \
		Vector2.ZERO)
		spawn_black_bar("BarRight", \
		Vector2(thickness + 2, window_height), \
		Vector2((right - left) + thickness - 1, 0))

		limit_left = left - thickness
		limit_right = right + thickness
	else:
		limit_left = left
		limit_right = right

	if get_window().get_size().y > (bottom - top) * vs.resolution_scale:
		#print("WARNING: window height larger than camera limit")
		var thickness = (window_height / vs.resolution_scale - (bottom - top))/2

		spawn_black_bar("BarTop", \
		Vector2(window_width, thickness + 1), \
		Vector2.ZERO)
		spawn_black_bar("BarBottom", \
		Vector2(window_width, thickness + 16), \
		Vector2(0, (bottom - top) + thickness - 1))  #16 for overscan safety

		limit_top = top - thickness
		limit_bottom = bottom + thickness
	else:
		limit_top = top
		limit_bottom = bottom

func spawn_black_bar(bar_name, size, bar_position):
		var bar = BLACKBAR.instantiate()
		bar.name = bar_name
		bar.size = size
		bar.position = bar_position
		w.bl.add_child(bar)
		w.bl.move_child(bar, 0)



### SIGNALS ###

func _resolution_scale_changed(resolution_scale):
	zoom = Vector2(resolution_scale, resolution_scale)
	reset()
