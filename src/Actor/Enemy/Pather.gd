extends Enemy

const ICON = preload("res://assets/Actor/Enemy/CrusherIcon.png")
const TX_0 = preload("res://assets/Actor/Enemy/Crusher.png")

@export var amplitude_v: float = 64
@export var amplitude_h: float = 0
@export var frequency: float = 2

var center_pos: Vector2
var time: float = 0

var t_body = null
var t_dir = null


func _ready():
	hp = 4
	reward = 2

	center_pos = global_position

func _physics_process(delta):
	if Engine.is_editor_hint():
		pass
	else:
		if disabled or dead:
			return

		time += delta * frequency
		position.y = center_pos.y + cos(time) * amplitude_v

		if t_body != null:
			crush_check()

		animate()



func on_crush_body_entered(body, dir):
	t_body = body.get_parent()
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
		$Sprite2D.frame = 1
	elif global_position.x > center_pos.x + (amplitude_h * .75):
		$Sprite2D.frame = 2

	elif global_position.y < center_pos.y - (amplitude_v * .75):
		$Sprite2D.frame = 3
	elif global_position.y > center_pos.y + (amplitude_v * .75):
		$Sprite2D.frame = 4

	else:
		$Sprite2D.frame = 0
