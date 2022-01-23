extends Enemy

export var height_tolerance = 7
export var cooldown_time = 1

#var move_dir = Vector2.ZERO

func _ready():
	hp = 4
	damage_on_contact = 1
	speed = Vector2(100, 200)
	gravity = 250
	
	level = 3
	
	#$FireCooldown.start(cooldown_time)


func _on_ActiveDetector_body_entered(body):
	$StateMachine.change_state("Active")


func _on_ActiveDetector_body_exited(body):
	$StateMachine.change_state("Idle")


func _on_JumpDetector_body_entered(body):
	$StateMachine.change_state("Jump")
