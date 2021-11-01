extends Area2D

#var sfx_click = load("res://assets/SFX/Placeholder/snd_switchweapon.ogg")
export var style: int = 0

var has_player_near = false
var active_player = null

func _ready():
	$Sprite.frame_coords.y = style


func on_body_entered(body):
	has_player_near = true
	active_player = body

func on_body_exited(body):
	has_player_near = false
	

func _input(event):
	if event.is_action_pressed("inspect") and has_player_near == true and active_player.disabled == false:
		toggle_fan()


func toggle_fan():
	$ClickSound.play()
	if $AnimationPlayer.is_playing():
		$AnimationPlayer.stop()
	else:
		$AnimationPlayer.play("Spin")
