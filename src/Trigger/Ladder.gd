extends Trigger

func _ready():
	trigger_type = "ladder"


func _on_Ladder_body_entered(body):
	active_bodies.append(body.get_parent())

func _on_Ladder_body_exited(body):
	if not get_overlap(body):
		if body.get_parent().mm.current_state == body.get_parent().mm.states["ladder"]:
			body.get_parent().mm.change_state("run")
	active_bodies.erase(body.get_parent())


func _physics_process(delta):
	for b in active_bodies:
		if not b.mm.current_state == b.mm.states["ladder"] and b.can_input:
			if Input.is_action_just_pressed("look_up") \
			or Input.is_action_just_pressed("look_down") and not b.is_on_floor() \
			or Input.is_action_just_pressed("look_down") and b.is_on_ssp:
				b.mm.change_state("ladder")
				b.position.x = position.x + 8
				b.position.y -= 1
