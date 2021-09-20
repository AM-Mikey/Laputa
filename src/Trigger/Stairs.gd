extends Area2D

var active_player = null
var has_player_near = false
var old_ground_cof: float

func _on_Stairs_body_entered(body):
	print("entered stairs")
	active_player = body
	has_player_near = true
	old_ground_cof = active_player.ground_cof
	active_player.ground_cof = 1
	
func _on_Stairs_body_exited(_body):
	print("left stairs")
	active_player.is_on_ladder = false
	has_player_near = false
	active_player.ground_cof = old_ground_cof

