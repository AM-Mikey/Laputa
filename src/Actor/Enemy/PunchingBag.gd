extends Enemy

const ICON = preload("res://assets/Actor/Enemy/PunchingBagIcon.png")

func setup(): #Reminder: no function called can use await
	self_knockback = true
	hp = 9999
	damage_on_contact = 0
	reward = 0
	w.emit_signal("finished_spawn_entities_step")
	change_state("idle")

func do_idle(_delta):
	velocity = calc_velocity(Vector2.ZERO)
	move_and_slide()
