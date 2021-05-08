extends Area2D

var used = false

var has_player_near = false
var active_player = null

func _ready():
	add_to_group("Container")
	if not used:
		$AnimationPlayer.play("Flash")

func _on_LifeCapsule_body_entered(body):
	has_player_near = true
	active_player = body


func _on_LifeCapsule_body_exited(body):
	has_player_near = false

func _input(event):
	if event.is_action_pressed("inspect") and has_player_near == true:
		if used == false:
			used = true
			$AnimationPlayer.play("Used")
			active_player.max_hp +=3
			active_player.hp = active_player.max_hp
			active_player.update_max_hp()
			active_player.update_hp()
			$AudioStreamPlayer.play()
			yield($AudioStreamPlayer, "finished")
			
			print("got life capsule")
