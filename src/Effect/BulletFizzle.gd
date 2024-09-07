extends Node2D

var type = "range"

@onready var ap = $AnimationPlayer

func _ready():
	match type:
		"armor": 
			ap.play("Diamond")
			am.play("bullet_clink")
		"bullet":
			ap.play("Circle")
			#am.play("")
		"range":
			ap.play("Star")
		"world": 
			ap.play("Diamond")
			am.play("bullet_thud")

	await $AnimationPlayer.animation_finished
	queue_free()
