extends CharacterBody2D

var just_spawned := true
var is_exiting_tree := false

func _ready():
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame


	#await get_tree().create_timer(0.01).timeout
	#print("done")
	just_spawned = false

### SIGNALS ###

func _on_tree_exiting():
	is_exiting_tree = true
