extends Enemy

export var dir = Vector2.LEFT
#var safe_distance = 100

onready var levels = get_tree().get_nodes_in_group("Levels")
onready var cl = get_parent().get_parent().get_node("CameraLimiter")

func _ready():
	disabled = true
	visible = false
	
	hp = 3
	damage_on_contact = 2
	speed = Vector2(100, 100)
	acceleration = 25
	
	level = 2

	
	if dir == Vector2.LEFT:
		$AnimationPlayer.play("FlyLeft")
	if dir == Vector2.RIGHT:
		$AnimationPlayer.play("FlyRight")
	
func _physics_process(delta):
	if not disabled:
#		if dir == Vector2.LEFT:
#			if position.x <= cl.get_node("Left").position.x - safe_distance:
#				print("freed ornithopter")
#				queue_free()
#		if dir == Vector2.RIGHT:
#			if position.x >= cl.get_node("Right").position.x + safe_distance:
#				print("freed ornithopter")
#				queue_free()

		move_and_slide(speed * dir)


func on_cue():
	visible = true
	disabled = false
