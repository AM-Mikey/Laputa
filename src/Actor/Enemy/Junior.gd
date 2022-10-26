extends Enemy

var starting_state = "walk"
export var move_dir = Vector2.LEFT
export var idle_max_time = 5.0
export var walk_max_time = 10.0
export var aim_time = 0.2
export var reload_time = 0.4

onready var ap = $AnimationPlayer
onready var st = $StateTimer

func setup():
	change_state(starting_state)
	hp = 6
	reward = 2
	damage_on_contact = 2
	speed = Vector2(50, 50)


### STATES ###

func enter_idle():
	do_flip_check()
	ap.play("Idle")
	rng.randomize()
	st.start(rng.randf_range(1.0, idle_max_time))
	yield(st, "timeout")
	print("idle to walk")
	change_state("walk")

func enter_walk():
	if not $FloorDetectorL.is_colliding() and move_dir.x < 0:
		move_dir = Vector2.RIGHT
	if not $FloorDetectorR.is_colliding() and move_dir.x > 0:
		move_dir = Vector2.LEFT
	do_flip_check()
	ap.play("Walk")
	rng.randomize()
	st.start(rng.randf_range(1.0, walk_max_time))
	yield(st, "timeout") #IT WILL CONTINUE THIS YIELD IN ANOTHER STATE, EVEN IF THE TIMER IS DEAD
	change_state("idle")

func do_walk():
	if not $FloorDetectorL.is_colliding() and move_dir.x < 0:
		change_state("idle")
	if not $FloorDetectorR.is_colliding() and move_dir.x > 0:
		change_state("idle")
	if $FloorDetectorL.is_colliding() or $FloorDetectorR.is_colliding():
		velocity = get_velocity(velocity, move_dir, speed)
		velocity = move_and_slide(velocity, FLOOR_NORMAL)

func enter_aim():
	velocity = Vector2(lerp(velocity.x, 0, 0.4), lerp(velocity.y, 0, 0.4))
	ap.play("Aim")
	yield(ap, "animation_finished")
	st.start(aim_time)
	yield(st,"timeout")
	change_state("shoot")

func enter_shoot():
	ap.play("Shoot")
	st.start(reload_time)
	yield(st,"timeout")
	ap.play("Shoot")


### HELPERS ###

func do_flip_check():
	match move_dir:
		Vector2.LEFT: 
			$Sprite.flip_h = false
			$PlayerDetector.scale.x = 1
		Vector2.RIGHT: 
			$Sprite.flip_h = true
			$PlayerDetector.scale.x = -1

### SIGNALS ###

func _on_PlayerDetector_body_entered(body):
	change_state("aim")


func _on_PlayerDetector_body_exited(body):
	pass # Replace with function body.
