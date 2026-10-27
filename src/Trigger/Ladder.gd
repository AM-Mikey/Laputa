extends Trigger

var bodies_allow_down: Array = []


func _ready():
	trigger_type = "ladder"
	#Set shape sizes
	$CollisionShape2D.shape.size.x = 8.0
	$AllowDownInput/CollisionShape2D.shape.size.x = 8.0
	$AllowDownInput/CollisionShape2D.shape.size.y = 1.0
	$AllowDownInput.position.x = 8.0
	$AllowDownInput.position.y = - 0.5
	w.emit_signal("finished_spawn_entities_step")

func _physics_process(_delta):
	for b in bodies_allow_down: #Allow down input
		if inp.can_act && !b.mm.current_state in [b.mm.states["ladder"],b.mm.states["fly"]]:
			if inp.pressed("look_down"):
				b.mm.change_state("ladder")
				b.position.x = position.x + 8
	for b in active_bodies: #Allow up and down input
		if inp.can_act && !b.mm.current_state in [b.mm.states["ladder"],b.mm.states["fly"]]:
			var is_on_solid_floor = true if b.is_on_floor() && !b.is_on_ssp else false
			if inp.pressed("look_up") || (inp.pressed("look_down") && !is_on_solid_floor):
				b.mm.change_state("ladder")
				b.position.x = position.x + 8



### SIGNALS

func _on_Ladder_body_entered(body):
	active_bodies.append(body.get_parent())

func _on_Ladder_body_exited(body):
	active_bodies.erase(body.get_parent())
	if body.get_parent().mm.current_state == body.get_parent().mm.states["ladder"]:
		body.get_parent().mm.change_state("run")

func _on_AllowDownInput_body_entered(body: Node2D) -> void:
	bodies_allow_down.append(body.get_parent())

func _on_AllowDownInput_body_exited(body: Node2D) -> void:
	var main_body = body.get_parent()
	bodies_allow_down.erase(main_body)
	if main_body not in active_bodies && main_body.mm.current_state == main_body.mm.states["ladder"]:
		main_body.mm.change_state("run")
