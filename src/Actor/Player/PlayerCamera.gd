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

@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_parent()
@onready var mm = pc.get_node("MovementManager")
var h_tween: Tween
var v_tween: Tween

func _ready():
	var _err = get_tree().root.connect("size_changed", Callable(self, "on_viewport_size_changed"))
	on_viewport_size_changed()

func _physics_process(_delta):
	if h_dir != pc.look_dir.x:
		h_dir = pc.look_dir.x
		pan_horizontal(pc.look_dir.x)

	if h_tween: #TODO: this should only run if h_tween is running
		h_tween.set_speed_scale(max(abs(mm.velocity.x)/mm.speed.x, h_pan_min_speed))
	
	if not pc.disabled and pc.can_input:
		if Input.is_action_just_pressed("look_up") or Input.is_action_just_pressed("look_down") \
		or Input.is_action_just_released("look_up") or Input.is_action_just_released("look_down"):
				pan_vertical(get_v_dir())


### MAIN ###

func pan_vertical(dir):
	var dist = v_pan_distance / world.resolution_scale
	if v_tween:
		v_tween.kill()
	v_tween = create_tween()
	v_tween.tween_property(self, "drag_vertical_offset", dir * dist, v_pan_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(v_pan_delay)

func pan_horizontal(dir):
	var dist = h_pan_distance / world.resolution_scale
	if h_tween:
		h_tween.kill()
	h_tween = create_tween()
	h_tween.tween_property(self, "drag_horizontal_offset", dir * dist, h_pan_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(h_pan_delay)

func stop_tween():
	h_tween.kill()
	v_tween.kill()

### GETTERS ###
func get_v_dir() -> int:
	var dir = 0
	if pc.can_input:
		if Input.is_action_pressed("look_up"): dir -= 1
		if Input.is_action_pressed("look_down"): dir += 1
	return dir

### TRIGGERS ###
func on_limit_camera(left, right, top, bottom):
	var window_width = get_window().get_size().x
	var window_height = get_window().get_size().y
	
	for b in get_tree().get_nodes_in_group("BlackBars"):
		b.free()
	
	if window_width > (right - left) * world.resolution_scale:
		#print("WARNING: window width larger than camera limit")
		var thickness = ((window_width / world.resolution_scale) - (right - left))/2
		
		spawn_black_bar("BarLeft", \
		Vector2(thickness, window_height), \
		Vector2.ZERO)
		spawn_black_bar("BarRight", \
		Vector2(thickness, window_height), \
		Vector2((right - left) + thickness, 0))
		
		limit_left = left - thickness
		limit_right = right + thickness
	else:
		limit_left = left
		limit_right = right
	
	if get_window().get_size().y > (bottom - top) * world.resolution_scale:
		#print("WARNING: window height larger than camera limit")
		var thickness = (window_height / world.resolution_scale - (bottom - top))/2
		
		spawn_black_bar("BarTop", \
		Vector2(window_width, thickness), \
		Vector2.ZERO)
		spawn_black_bar("BarBottom", \
		Vector2(window_width, thickness), \
		Vector2(0, (bottom - top) + thickness))
		
		limit_top = top - thickness
		limit_bottom = bottom  + thickness
	else:
		limit_top = top
		limit_bottom = bottom

func spawn_black_bar(bar_name, size, bar_position):
		var ui = world.get_node("UILayer")
		var bar = BLACKBAR.instantiate()
		bar.name = bar_name
		bar.size = size
		bar.position = bar_position
		ui.add_child(bar)
		ui.move_child(bar, 0)


func on_viewport_size_changed():
	zoom = Vector2(world.resolution_scale, world.resolution_scale)
