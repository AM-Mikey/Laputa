extends Area2D

var has_player_near = false
var active_player = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_Lamp_body_entered(body):
	has_player_near = true
	active_player = body

func _on_Lamp_body_exited(body):
	has_player_near = false
	

func _input(event):
	if event.is_action_pressed("inspect") and has_player_near == true and active_player.disabled == false:
		toggle_lamp()


func toggle_lamp():
	if $Sprite.frame_coords.y == 1:
		$Sprite.frame_coords.y = 0
	elif $Sprite.frame_coords.y == 0:
		$Sprite.frame_coords.y = 1


