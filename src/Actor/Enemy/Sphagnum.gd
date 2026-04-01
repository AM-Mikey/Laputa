extends Enemy

const ICON = preload("res://assets/Actor/Enemy/SphagnumIcon.png")



func _ready():
	hp = 4
	damage_on_contact = 2
	reward = 2

	$AnimationPlayer.play("Idle")
