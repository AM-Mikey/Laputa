extends Trigger

var bodies_allow_down: Array = []

func _ready():
	trigger_type = "ladder"
	#Make the down area that's 1 pixel in y size and on top of the ladder to detect any bodies at the top
	#Half the main area width to avoid player looks like teleporting to the ladder
	$AllowDownInput/CollisionShape2D.shape.size.x = $CollisionShape2D.shape.size.x / 2.0
	$AllowDownInput/CollisionShape2D.shape.size.y = 1.0
	$AllowDownInput.position.x = $CollisionShape2D.shape.size.x / 2.0
	$AllowDownInput.position.y = - 0.5

func _physics_process(_delta):
	for b in bodies_allow_down: #Allow down input
		if not b.mm.current_state == b.mm.states["ladder"] and b.can_input:
			if Input.is_action_just_pressed("look_down"):
				b.mm.change_state("ladder")
				b.position.x = position.x + 8
	for b in active_bodies: #Allow up and down input
		if not b.mm.current_state == b.mm.states["ladder"] and b.can_input:
			if Input.is_action_just_pressed("look_up") or Input.is_action_just_pressed("look_down"):
				b.mm.change_state("ladder")
				b.position.x = position.x + 8


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
	if main_body not in active_bodies and main_body.mm.current_state == main_body.mm.states["ladder"]:
		main_body.mm.change_state("run")
