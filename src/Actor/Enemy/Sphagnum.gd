extends Enemy

const ICON = preload("res://assets/Actor/Enemy/SphagnumIcon.png")



func setup(): #Reminder: no function called can use await
	hp = 4
	damage_on_contact = 2
	reward = 2
	$AnimationPlayer.play("Idle")
	w.emit_signal("finished_spawn_entities_step")
