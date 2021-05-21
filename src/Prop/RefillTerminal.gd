extends Area2D

var no_sound = load("res://assets/SFX/snd_quote_bonkhead.ogg")

var has_player_near = false
var active_player = null

func _ready():
	$AnimationPlayer.play("Flash")

func _on_RefillTerminal_body_entered(body):
	has_player_near = true
	active_player = body


func _on_RefillTerminal_body_exited(body):
	has_player_near = false

func _input(event):
	if event.is_action_pressed("inspect") and has_player_near == true:
		if active_player.hp < active_player.max_hp:
			active_player.restore_hp()
			print("restored hp to full")
		else:
			$Audio.stream = no_sound
			$Audio.play()
