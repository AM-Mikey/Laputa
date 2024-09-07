extends Enemy

@export var start_dir = Vector2.LEFT

var move_dir

func _ready():
	hp = 3
	reward = 2
	damage_on_contact = 2
	speed = Vector2(60, 60)
	acceleration = 50
	gravity = 200
	move_dir = start_dir
	set_up_direction(FLOOR_NORMAL)
	animate()
	
	
	
func _on_physics_process(_delta):
	if disabled or dead: return
	velocity = calc_velocity(velocity, move_dir, speed)
	move_and_slide()

	if is_on_wall():
		move_dir *= -1
		am.play("enemy_jump", self)
		animate()

func animate():
	$AnimationPlayer.play("Roll")
	match move_dir:
		Vector2.LEFT: $Sprite2D.flip_h = false
		Vector2.RIGHT: $Sprite2D.flip_h = true
