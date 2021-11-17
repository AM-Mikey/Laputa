extends Area2D

var used = false

var has_player_near = false
var pc = null

func _ready():
	add_to_group("Containers")
	if not used:
		$AnimationPlayer.play("Flash")

func _on_LifeCapsule_body_entered(body):
	has_player_near = true
	pc = body


func _on_LifeCapsule_body_exited(_body):
	has_player_near = false

func _input(event):
	if event.is_action_pressed("inspect") and has_player_near == true and pc.disabled == false:
		if used == false:
			used = true
			$AnimationPlayer.play("Used")
			pc.max_hp +=2
			pc.hp = pc.max_hp
			pc.emit_signal("hp_updated", pc.hp, pc.max_hp)
			$AudioStreamPlayer.play()
			yield($AudioStreamPlayer, "finished")
			
			print("got life capsule")
