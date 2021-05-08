extends Area2D

export var held_item: String

var get_sound = load("res://assets/SFX/snd_chest_open.ogg")

var used = false
var has_player_near = false
var active_player = null

func _ready():
	add_to_group("Container")
	if not used:
		$AnimationPlayer.play("Shine")
	
func _on_Chest_body_entered(body):
	has_player_near = true
	active_player = body
func _on_Chest_body_exited(body):
	has_player_near = false

func _input(event):
	if event.is_action_pressed("inspect") and has_player_near == true:
		if used == false:
			used = true
			$AnimationPlayer.play("Used")
			$AudioStreamPlayer.stream = get_sound
			$AudioStreamPlayer.play()
			active_player.inventory.append(held_item)
			print("added item '", held_item, "' to inventory")
			active_player.update_inventory()
