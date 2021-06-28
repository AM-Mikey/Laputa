extends Enemy

export var starting_direction = Vector2.LEFT
var move_dir: Vector2
var waiting = false
export var wait_time = 1.0

func _ready():
	hp = 4
	damage_on_contact = 2
	speed = Vector2(100, 100)
	move_dir = starting_direction
	animate(move_dir)

func _physics_process(delta):
	get_parent().offset += speed.x/100


func animate(move_dir):
	if move_dir == Vector2.LEFT:
		$AnimationPlayer.play("MoveLeft")
	if move_dir == Vector2.RIGHT:
		$AnimationPlayer.play("MoveRight")
