extends Enemy




func _ready():
	hp = 4
	damage_on_contact = 2
	reward = 2
	
	$AnimationPlayer.play("Idle")
