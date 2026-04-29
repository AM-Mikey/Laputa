extends CharacterBody2D

var just_spawned := true

func _ready():
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	#await get_tree().create_timer(0.01).timeout
	#print("done")
	just_spawned = false
