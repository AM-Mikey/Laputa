extends Enemy

const ICON = preload("res://assets/Actor/Enemy/OrnithopterIcon.png")

@export var dir = Vector2.LEFT

func setup():
	disabled = false
	visible = true

	hp = 3
	damage_on_contact = 2
	speed = Vector2(100, 100)
	acceleration = 25

	reward = 0

	if dir == Vector2.LEFT:
		$AnimationPlayer.play("FlyLeft")
	if dir == Vector2.RIGHT:
		$AnimationPlayer.play("FlyRight")

func _physics_process(_delta):
	if disabled or dead:
		return

	velocity = calc_velocity(dir, false)
	move_and_slide()
