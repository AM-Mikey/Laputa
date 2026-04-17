extends Enemy

const ICON = preload("res://assets/Actor/Enemy/OrnithopterIcon.png")

@export var dir = Vector2.LEFT
#var safe_distance = 100

#@onready var levels = get_tree().get_nodes_in_group("Levels")
#@onready var cl = get_parent().get_parent().get_node("CameraLimiter")

func _ready():
	disabled = false
	visible = true

	hp = 3
	damage_on_contact = 2
	speed = Vector2(100, 100)
	acceleration = 25

	reward = 2


	if dir == Vector2.LEFT:
		$AnimationPlayer.play("FlyLeft")
	if dir == Vector2.RIGHT:
		$AnimationPlayer.play("FlyRight")

func _physics_process(_delta):
	if disabled or dead:
		return

	velocity = calc_velocity(dir, false)
	move_and_slide()


func on_cue():
	visible = true
	disabled = false
