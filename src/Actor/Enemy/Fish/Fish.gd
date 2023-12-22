@tool
extends Enemy


const PATH_LINE = preload("res://src/Utility/PathLine.tscn")


var move_dir = Vector2.LEFT
@export var swim_dir_x = -1: set = on_swim_dir_x_changed
@export var jump_height: int = 6: set = on_jump_height_changed
@onready var start_pos = position
var jump_pos

@export var can_move_x = true
@export var x_min = -3: set = on_x_min_changed
@export var x_max = 3: set = on_x_max_changed


func _ready():
	if debug: print("ready fish")
	speed = Vector2(20,150)
	damage_on_contact = 1
	update_path_lines()


func _physics_process(_delta):
	if not Engine.is_editor_hint():
		gravity = 300.0 if not is_in_water else 150.0


func on_swim_dir_x_changed(new):
	swim_dir_x = new
	$Sprite2D.scale.x = new
	move_dir.x = new

func on_jump_height_changed(new):
	jump_height = new
	jump_pos = Vector2(position.x, position.y + new * -16)
	update_path_lines()

func on_x_min_changed(new):
	x_min = new
	update_path_lines()
	
func on_x_max_changed(new):
	x_max = new
	update_path_lines()
	
func update_path_lines():
	#if Engine.editor_hint or debug:
	for c in get_children():
		if c.name == "VPath" or c.name == "HPath": c.free()
	
	var vline = PATH_LINE.instantiate()
	vline.name = "VPath"
	vline.default_color = Color.LIGHT_GREEN
	if Engine.is_editor_hint(): 
		vline.add_point(Vector2.ZERO)
		vline.add_point(Vector2(0, jump_height * -16))
		add_child(vline)
		move_child(vline, 0)
	elif debug and world:
		vline.add_point(position)
		vline.add_point(jump_pos)
		world.front.add_child(vline)
	
	$RayCast2D.target_position = Vector2(0, jump_height * -16)

	var hline = PATH_LINE.instantiate()
	hline.name = "HPath"
	hline.default_color = Color.RED
	if Engine.is_editor_hint(): 
		hline.add_point(Vector2(x_min * 16,0))
		hline.add_point(Vector2(x_max * 16,0))
		add_child(hline)
		move_child(hline, 0)
	elif debug and world:
		hline.add_point(position + Vector2(x_min * 16,0))
		hline.add_point(position + Vector2(x_max * 16,0))
		world.front.add_child(hline)
