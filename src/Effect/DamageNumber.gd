extends Node2D

var value: int = 0

func display_number():
	if value > 0 and value < 10:
		$Layer/Num1.frame_coords.x = value
		$Layer/Num2.visible = false
		$Layer/Num3.visible = false
	elif value >= 10 and value < 100:
		$Layer/Num1.frame_coords.x = (value % 100) / 10
		$Layer/Num2.frame_coords.x = value % 10
		$Layer/Num3.visible = false
	elif value >= 100 and value < 1000:
		$Layer/Num1.frame_coords.x = (value % 1000) / 100
		$Layer/Num2.frame_coords.x = (value % 100) / 10
		$Layer/Num3.frame_coords.x = value % 10
	elif value >= 1000:
		$Layer/Num1.frame_coords.x = 9
		$Layer/Num2.frame_coords.x = 9
		$Layer/Num3.frame_coords.x = 9
	else:
		print("ERROR: No damage applied to damagenumber")
