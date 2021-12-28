extends Trigger

func _ready():
	trigger_type = "ladder"


func _on_Ladder_body_entered(body):
	active_pc = body

func _on_Ladder_body_exited(_body):
	if not get_overlap():
		active_pc.get_node("MovementManager").change_state(active_pc.get_node("MovementManager").states["normal"])
	
	active_pc = null


func _physics_process(delta):
	if active_pc and not active_pc.get_node("MovementManager").current_state == active_pc.get_node("MovementManager").states["ladder"]:
		if Input.is_action_just_pressed("look_up") \
		or Input.is_action_just_pressed("look_down") and not active_pc.is_on_floor() \
		or Input.is_action_just_pressed("look_down") and active_pc.is_on_ssp:
			active_pc.get_node("MovementManager").change_state(active_pc.get_node("MovementManager").states["ladder"])
			active_pc.position.x = position.x + 8
			active_pc.position.y -= 1
