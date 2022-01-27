tool
extends Enemy

const PATH_LINE = preload("res://src/Utility/PathLine.tscn")

export var amplitude_v: float = 64 setget on_amplitude_v_changed
export var amplitude_h: float = 0 setget on_amplitude_h_changed
export var frequency: float = 2

var center_pos: Vector2
var time: float = 0

var t_body = null
var t_dir = null


onready var pc = get_tree().get_root().get_node("World/Juniper")

func _ready():
	hp = 4
	level = 2

	center_pos = global_position

func on_amplitude_v_changed(new_amplitude):
	amplitude_v = new_amplitude
	
	if Engine.editor_hint:
		for c in get_children():
			if c.name == "PathV": c.free()
			
		var line = PATH_LINE.instance()
		line.add_point(Vector2(0, new_amplitude * -1))
		line.add_point(Vector2(0, new_amplitude))
		line.name = "PathV"
		add_child(line)
		move_child(line, 0)

func on_amplitude_h_changed(new_amplitude):
	amplitude_h = new_amplitude
	
	if Engine.editor_hint:
		for c in get_children():
			if c.name == "PathH": c.free()
				
		var line = PATH_LINE.instance()
		line.add_point(Vector2(new_amplitude * -1, 0))
		line.add_point(Vector2(new_amplitude, 0 ))
		line.name = "PathH"
		add_child(line)
		move_child(line, 0)


func _physics_process(delta):
	if Engine.editor_hint:
		pass
	else:
		if not dead and not disabled:
	#		if pc.is_on_floor():
	#			damage_on_contact = 999
	#		else:
	#			damage_on_contact = 1
			
			time += delta * frequency
			position.y = center_pos.y + cos(time) * amplitude_v
			
			if t_body != null:
				crush_check()
			
			animate()
		
		


func on_crush_body_entered(body, dir):
	t_body = body
	t_dir = dir
func on_crush_body_exited(body):
	t_body = null
	t_dir = null

func crush_check():
	match t_dir:
		"up":
			if t_body.is_on_ceiling():
				t_body.hit(999, Vector2.ZERO)
		"down":
			if t_body.is_on_floor():
				t_body.hit(999, Vector2.ZERO)


func animate():
	if global_position.x < center_pos.x - (amplitude_h * .75):
		$Sprite.frame = 1
	elif global_position.x > center_pos.x + (amplitude_h * .75):
		$Sprite.frame = 2
	
	elif global_position.y < center_pos.y - (amplitude_v * .75):
		$Sprite.frame = 3
	elif global_position.y > center_pos.y + (amplitude_v * .75):
		$Sprite.frame = 4
	
	else:
		$Sprite.frame = 0
