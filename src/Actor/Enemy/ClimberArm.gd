extends Enemy

var index: int


func on_WorldDetector_body_entered(body: Node2D) -> void:
	pass # Replace with function body.

func do_death_routine():
	get_parent().get_parent().replace_arms(index)
