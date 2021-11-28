extends Area2D

#var sfx_click = load("res://assets/SFX/Placeholder/snd_switchweapon.ogg")
export var style: int = 0

var has_player_near = false
var active_player = null

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite.frame_coords.y = style


func _on_Lamp_body_entered(body):
	has_player_near = true
	active_player = body

func _on_Lamp_body_exited(_body):
	has_player_near = false
	

func _input(event):
	if event.is_action_pressed("inspect") and has_player_near == true and active_player.disabled == false:
		toggle_lamp()


func toggle_lamp():
	$ClickSound.play()
	if $Sprite.frame_coords.x == 1:
		$Sprite.frame_coords.x = 0
		$Light2D.enabled = false
	elif $Sprite.frame_coords.x == 0:
		$Sprite.frame_coords.x = 1
		$Light2D.enabled = true


