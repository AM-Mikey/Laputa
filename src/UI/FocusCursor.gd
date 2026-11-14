class_name FocusCursor
extends Panel
## Box cursor that tweens its position and size to wrap whichever
## Control currently has GUI focus (Godot 4.x).
##
## Setup: add a Panel node anywhere in your UI tree (a CanvasLayer child
## works well so it draws above everything), attach this script, and give
## the Panel a StyleBoxFlat (transparent fill + border) for the look.

@export var padding := Vector2(6, 6)        ## extra space around the target on each side
@export var duration := 0.18                ## tween time in seconds
@export var trans := Tween.TRANS_QUART
@export var ease_type := Tween.EASE_OUT
@export var hide_when_no_focus := true

var _target: Control = null
var _last_rect := Rect2()
var _tween: Tween


func _ready() -> void:
	top_level = true                         # ignore parent containers / transforms
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2.ZERO
	z_index = 100
	visible = false
	get_viewport().gui_focus_changed.connect(_on_focus_changed)

	# Pick up whatever is already focused.
	var current := get_viewport().gui_get_focus_owner()
	if current:
		_on_focus_changed(current)


func _on_focus_changed(control: Control) -> void:
	if control == null or control == self or not is_instance_valid(control):
		_target = null
		if hide_when_no_focus:
			visible = false
		return

	var first_time := not visible
	_target = control
	visible = true
	_last_rect = Rect2()                     # force a retarget next frame

	if first_time:
		# Appear in place instead of flying in from wherever we were last.
		var rect := _get_target_rect()
		global_position = rect.position
		size = rect.size
		_last_rect = rect


func _process(_delta: float) -> void:
	if _target == null:
		return
	if not is_instance_valid(_target) or not _target.is_visible_in_tree():
		_target = null
		if hide_when_no_focus:
			visible = false
		return

	# Retarget whenever the focused control moves or resizes (including
	# being scrolled or re-laid-out by a container), not just on focus change.
	var rect := _get_target_rect()
	if not rect.is_equal_approx(_last_rect):
		_last_rect = rect
		_tween_to(rect)


func _get_target_rect() -> Rect2:
	var rect := _target.get_global_rect()
	return rect.grow_individual(padding.x, padding.y, padding.x, padding.y)


func _tween_to(rect: Rect2) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.set_trans(trans)
	_tween.set_ease(ease_type)
	_tween.tween_property(self, "global_position", rect.position, duration)
	_tween.tween_property(self, "size", rect.size, duration)
