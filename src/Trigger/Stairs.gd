extends Trigger

var old_ground_cof: float

func _ready():
	trigger_type = "stairs"

func _on_body_entered(body):
	active_pc = body
	old_ground_cof = active_pc.get_node("MovementManager").ground_cof
	active_pc.get_node("MovementManager").ground_cof = 1
	
func _on_body_exited(_body):
	active_pc.get_node("MovementManager").ground_cof = old_ground_cof

