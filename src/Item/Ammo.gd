extends Area2D

var value: float

export var ammo: float

func _ready():
	if value <= 0.2:
		$AnimationPlayer.play("Small")
	else:
		$AnimationPlayer.play("Large")
