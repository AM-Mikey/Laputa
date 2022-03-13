tool
extends Control

var state = "idle"

var drag_offset = Vector2.ZERO

export var bar_thickness = 16 setget on_bar_height_changed
export var bar_offset = 0 setget on_bar_offset_changed
export var debug = false


func _ready():
	add_bar()
	setup_bar()
	add_reference()

func add_bar():
	var bar = Button.new()
	bar.flat = true
	bar.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	bar.rect_size.y = bar_thickness
	bar.rect_position.y = bar_offset
	bar.name = "Bar"
	add_child(bar)
	bar.connect("pressed", self, "on_bar_pressed")
	

#func _input(event):
#	if event.is_action_pressed("editor_lmb"):
#		var event_pos = event.global_position
#		var bar_pos = $Bar.rect_position
#		var bar_size = $Bar.rect_size
#		var target_rect = Rect2(bar_pos.x, bar_pos.y, bar_size.x, bar_size.y)
#
#		if target_rect.has_point(event_pos):
#			print("clicked")

func on_bar_pressed():
	print("ashfaishfd")
	state = "drag"
	drag_offset =  rect_global_position - get_global_mouse_position()

func _input(event):
	if state == "drag":
		if event is InputEventMouseMotion:
			rect_position = get_global_mouse_position() + drag_offset
		if event.is_action_released("editor_lmb"):
			state = "idle"

func on_bar_height_changed(new):
	bar_thickness = new
	if Engine.editor_hint:
		setup_bar()
		add_reference()

func on_bar_offset_changed(new):
	bar_offset = new
	if Engine.editor_hint:
		setup_bar()
		add_reference()
	
func setup_bar():
	$Bar.rect_size.x = rect_size.x
	$Bar.rect_size.y = bar_thickness
	$Bar.rect_position.y = bar_offset
	
func add_reference():
	for c in get_children():
		if c is ReferenceRect:
			c.free()
	var ref = ReferenceRect.new()
	ref.mouse_filter = MOUSE_FILTER_IGNORE
	ref.rect_size = $Bar.rect_size
	ref.rect_position = $Bar.rect_position
	if debug:
		ref.editor_only = false
	add_child(ref)
