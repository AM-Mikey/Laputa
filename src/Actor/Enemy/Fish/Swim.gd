extends State

#var state_name = "Swim"

@onready var em = get_parent().get_parent()
@onready var ap = em.get_node("AnimationPlayer")
@onready var rc = em.get_node("RayCast2D")


func state_process():
	rc.position.x = 4 * em.move_dir.x
	
	var collision = rc.get_collider()
	if collision != null:
		if collision.get_collision_layer_value(1): #player
			if em.debug: print("got target")
			sm.change_state("attack")
	
	
	if em.position.x < em.start_pos.x + em.x_min * 16:
		em.swim_dir_x = 1
	if em.position.x > em.start_pos.x + em.x_max * 16:
		em.swim_dir_x = -1
	
	em.set_velocity(calc_velocity())
	em.move_and_slide()
	em.velocity = em.velocity


func calc_velocity() -> Vector2:
	var out = em.velocity
	
	out.x = em.speed.x * em.move_dir.x
	
	return out

func enter():
	em.move_dir.x = em.swim_dir_x
	ap.play("Idle")

func exit():
	rc.position = Vector2.ZERO
	em.move_dir = Vector2.ZERO
	em.velocity = Vector2.ZERO
