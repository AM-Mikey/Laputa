@tool
extends Enemy

const PATH_LINE = preload("res://src/Utility/PathLine.tscn")

@export var jump_height: int = 6: set = on_jump_height_changed
@export var cooldown_time = 1
var kick_damage = 4

var move_dir = Vector2.ZERO
var target = null
@onready var start_pos = position
var jump_pos

func on_jump_height_changed(new):
	jump_height = new
	jump_pos = Vector2(position.x, position.y + new * -16)
	update_path_lines()

func _ready():
	hp = 4
	damage_on_contact = 1
	speed = Vector2(100, 200)
	gravity = 250
	
	reward = 3
	on_jump_height_changed(jump_height)
	#update_path_lines()


func _on_ActiveDetector_body_entered(body):
	if not Engine.is_editor_hint():
		if $StateMachine.current_state == $StateMachine/Idle:
			$StateMachine.change_state("Active")


func _on_ActiveDetector_body_exited(_body):
	if not Engine.is_editor_hint():
		if $StateMachine.current_state == $StateMachine/Active:
			$StateMachine.change_state("Idle")


func _on_JumpDetector_body_entered(_body):
	if not Engine.is_editor_hint():
		if $StateMachine.current_state == $StateMachine/Active:
			$StateMachine.change_state("Rise")


func _on_KickDectector_body_entered(body):
	if not Engine.is_editor_hint():
		if $StateMachine.current_state == $StateMachine/Rise:
			target = body
			$StateMachine.change_state("Kick")
		

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


#	var hline = PATH_LINE.instance()
#	hline.name = "HPath"
#	hline.default_color = Color.red
#	if Engine.editor_hint: 
#		hline.add_point(Vector2(x_min * 16,0))
#		hline.add_point(Vector2(x_max * 16,0))
#		add_child(hline)
#		move_child(hline, 0)
#	elif debug and world:
#		hline.add_point(position + Vector2(x_min * 16,0))
#		hline.add_point(position + Vector2(x_max * 16,0))
#		world.front.add_child(hline)
