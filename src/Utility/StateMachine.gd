extends Node2D

class_name StateMachine

@export var main: Node = get_parent()
@export var start_state: State = null

@export_group("Debug")
@export var debug: bool = false
@export var debug_font: FontFile = preload("res://assets/UI/Font/welcomeback.ttf")
@export var debug_font_size: int = 16
@export var debug_font_color: Color = Color.WHITE
@export var debug_font_outline_size: int = 4
@export var debug_font_outline_color: Color = Color.BLACK

var state: String = ""
var curr_state: State = null

func _ready():
	if !start_state:
		push_error("Missing a start state.")
		return
	await main.ready
	change_state(start_state.name)

func _draw():
	if debug:
		var string: String =  "<null>" if !curr_state else state.to_snake_case()
		var string_size = debug_font.get_string_size(string, HORIZONTAL_ALIGNMENT_CENTER)
		draw_string_outline(debug_font,
					Vector2(-string_size.x / 2.0, -5.0), string,
					HORIZONTAL_ALIGNMENT_LEFT, -1.0, debug_font_size, debug_font_outline_size, debug_font_outline_color)
		draw_string(debug_font,
					Vector2(-string_size.x / 2.0, -5.0), string,
					HORIZONTAL_ALIGNMENT_LEFT, -1.0, debug_font_size, debug_font_color)


func change_state(sname: StringName):
	var next_state_name = sname.to_pascal_case()
	var next_state: State = get_node_or_null(next_state_name)
	if !next_state:
		push_warning("Cannot find state: ", next_state)
		return false

	var prev_state_name = state
	if curr_state:
		curr_state.state_end(next_state_name)
	curr_state = next_state
	state = next_state_name
	next_state.state_start(prev_state_name)
	return true

func _input(event: InputEvent):
	if curr_state:
		curr_state.state_input(event)

func _unhandled_input(event: InputEvent):
	if curr_state:
		curr_state.state_unhandled_input(event)

func _physics_process(delta: float):
	if curr_state:
		curr_state.state_physics_process(delta)
	if debug:
		queue_redraw()

func _process(delta: float):
	if curr_state:
		curr_state.state_process(delta)
