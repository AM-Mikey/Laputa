extends Enemy

export var move_dir = Vector2.LEFT
var idle_time = 2
var fly_speed = Vector2(100, 100)

func _ready():
	state = "idle"
	hp = 4
	reward = 2
	damage_on_contact = 2

func _physics_process(_delta):
	if disabled or dead:
		return
	velocity = get_velocity(velocity, move_dir, speed)
	velocity = move_and_slide(velocity, FLOOR_NORMAL)
	

func enter_idle():
	speed = Vector2.ZERO
	$AnimationPlayer.play("Idle")
	$Sprite.flip_h = false if move_dir.x > 0 else true
	$Sprite.rotation_degrees = 90 if move_dir.x > 0 else -90
	$Sprite.flip_v = true if move_dir.y < 0 else false #flip if down
	yield(get_tree().create_timer(idle_time), "timeout")
	change_state("fly")

func enter_fly():
	speed = fly_speed
	$AnimationPlayer.play("Fly")
	$Sprite.rotation_degrees = 0
	$Sprite.flip_h = true if move_dir.x > 0 else false #flip if right


func do_fly():
	if (abs(velocity.x) < 1 and abs(move_dir.x) > 0) or (abs(velocity.y) < 1 and abs(move_dir.y) > 0): #speed in direction you were goin is 0
		move_dir *= -1 #flip
		change_state("idle")
