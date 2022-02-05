extends Camera2D

const BLACKBAR = preload("res://src/Utility/BlackBar.tscn")

var horizontal_focus = Vector2.LEFT
var homing_camera = false
var panning_up = false
var panning_down = false

onready var world = get_tree().get_root().get_node("World")
onready var pc = get_tree().get_root().get_node("World/Juniper")
onready var mm = pc.get_node("MovementManager")

func _ready():
	add_to_group("Cameras")
	var _err = get_tree().root.connect("size_changed", self, "on_viewport_size_changed")
	on_viewport_size_changed()

func _physics_process(_delta):
	if horizontal_focus != pc.face_dir:
		horizontal_focus = pc.face_dir
		pan_horizontal(pc.face_dir)

	
	if $TweenHorizontal.is_active():
		$TweenHorizontal.playback_speed = max(abs(mm.velocity.x)/mm.speed.x, 0.5) #second number is minimum camera speed
	
	if not pc.disabled:
		if Input.is_action_just_pressed("look_up"):
			if panning_down:
				panning_up = false
				home_vertical()
			elif not panning_up:
				panning_up = true
				pan_vertical(-1)

		if Input.is_action_just_pressed("look_down"):
			if panning_up:
				panning_down = false
				home_vertical()
			elif not panning_down:
				panning_down = true
				pan_vertical(1)

		if Input.is_action_just_released("look_up"):
			if Input.is_action_pressed("look_down"):
				panning_down = true
				pan_vertical(1)
			else:
				panning_up = false
				home_vertical()
		
		if Input.is_action_just_released("look_down"):
			if Input.is_action_pressed("look_up"):
				panning_up = true
				pan_vertical(-1)
			else:
				panning_down = false
				home_vertical()


func _on_limit_camera(left, right, top, bottom):
	#print("limit camera")
	var bars = get_tree().get_nodes_in_group("BlackBars")
	for b in bars:
		b.free()
	
	
	if  OS.get_window_size().x > (right - left) * world.resolution_scale:
		print("WARNING: window width larger than camera limit")
		var extra_margin = ((OS.get_window_size().x / world.resolution_scale) - (right - left))/2
		
		limit_left = left - extra_margin
		limit_right = right + extra_margin
		
		var left_pillar = BLACKBAR.instance()
		left_pillar.name = "BlackBarLeft"
		left_pillar.rect_size = Vector2(extra_margin, OS.get_window_size().y)
		world.get_node("UILayer").add_child(left_pillar)
		world.get_node("UILayer").move_child(left_pillar, 0)
		
		var right_pillar = BLACKBAR.instance()
		right_pillar.name = "BlackBarRight"
		right_pillar.rect_size = Vector2(extra_margin, OS.get_window_size().y)
		right_pillar.rect_position = Vector2((right - left) + extra_margin, 0)
		world.get_node("UILayer").add_child(right_pillar)
		world.get_node("UILayer").move_child(right_pillar, 0)
		
	else:
		limit_left = left
		limit_right = right
	
	if OS.get_window_size().y > (bottom - top) * world.resolution_scale:
		print("WARNING: window height larger than camera limit")
		var extra_margin = (OS.get_window_size().y - (bottom - top))/2
		limit_top = top - extra_margin
		limit_bottom = bottom  + extra_margin
		
		var top_pillar = BLACKBAR.instance()
		top_pillar.name = "BlackBarTop"
		top_pillar.rect_size = Vector2(OS.get_window_size().x, extra_margin)
		world.get_node("UILayer").add_child(top_pillar)
		world.get_node("UILayer").move_child(top_pillar, 0)
		
		var bottom_pillar = BLACKBAR.instance()
		bottom_pillar.name = "BlackBarRight"
		bottom_pillar.rect_size = Vector2(OS.get_window_size().x, extra_margin)
		bottom_pillar.rect_position = Vector2(0, (bottom - top) + extra_margin)
		world.get_node("UILayer").add_child(bottom_pillar)
		world.get_node("UILayer").move_child(bottom_pillar, 0)
	
	else:
		limit_top = top
		limit_bottom = bottom



func pan_vertical(direction):
	var tween = $TweenVertical
	var camera_pan_distance = 2 / world.resolution_scale
	var camera_pan_time = 1.5
	var camera_pan_delay = 0
	
	yield(get_tree().create_timer(camera_pan_delay), "timeout")
	
	if tween.is_active():
		tween.stop_all()
	tween.interpolate_property(self, "offset_v", offset_v, direction * camera_pan_distance, camera_pan_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()

func home_vertical():
	#print("home vert")
	var tween = $TweenVertical
	var camera_pan_time = 1.5
	
	if tween.is_active():
		tween.stop_all()
	tween.interpolate_property(self, "offset_v", offset_v, 0, camera_pan_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()


func pan_horizontal(direction):
	#print("pan horz")
	var tween = $TweenHorizontal
	var camera_pan_distance = 2.0 / world.resolution_scale
	var camera_pan_time = 1.5

	if tween.is_active():
		tween.stop_all()
	tween.interpolate_property(self, "offset_h", offset_h, direction.x * camera_pan_distance, camera_pan_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()



func home_horizontal():
	#print("home horz")
	var tween = $TweenHorizontal
	var camera_pan_time = 1.5
	
	if tween.is_active():
		tween.stop_all()
	tween.interpolate_property(self, "offset_h", offset_h, 0, camera_pan_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()

func stop_tween():
	$TweenHorizontal.stop_all()
	$TweenVertical.stop_all()


func on_viewport_size_changed():
	zoom = Vector2(1.0 / world.resolution_scale, 1.0 / world.resolution_scale)
