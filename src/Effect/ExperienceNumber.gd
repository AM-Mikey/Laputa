extends Node2D

var value: int = -1
var combo_time = 0.5

func _ready():
	display_number()
	$AnimationPlayer.play("FloatIn")
	$Timer.start(combo_time)
	
func display_number():
	if value >= 0 and value < 10:
		$Layer/Num1.frame_coords.x = value
		$Layer/Num2.visible = false
		$Layer/Num3.visible = false
	elif value >= 10 and value < 100:
# warning-ignore:integer_division
		$Layer/Num1.frame_coords.x = int((value % 100) / 10.0)
		$Layer/Num2.frame_coords.x = value % 10
		$Layer/Num3.visible = false
	elif value >= 100 and value < 1000:
# warning-ignore:integer_division
		$Layer/Num1.frame_coords.x = int((value % 1000) / 100.0)
# warning-ignore:integer_division
		$Layer/Num2.frame_coords.x = int((value % 100) / 10.0)
		$Layer/Num3.frame_coords.x = value % 10
	elif value >= 1000:
		$Layer/Num1.frame_coords.x = 9
		$Layer/Num2.frame_coords.x = 9
		$Layer/Num3.frame_coords.x = 9
	else:
		printerr("ERROR: No value applied to experience_number")


func _on_Timer_timeout():
	$AnimationPlayer.play("FloatOut")
	await $AnimationPlayer.animation_finished
	queue_free()
