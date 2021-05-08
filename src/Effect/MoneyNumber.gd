extends Node2D

var value: int = 0

func display_number():
	if value >= 0 and value < 10:
		$Num1.frame_coords.x = value
		$Num2.visible = false
		$Num3.visible = false
	elif value >= 10 and value < 100:
		$Num1.frame_coords.x = (value % 100) / 10
		$Num2.frame_coords.x = value % 10
		$Num3.visible = false
	elif value >= 100 and value < 1000:
		$Num1.frame_coords.x = (value % 1000) / 100
		$Num2.frame_coords.x = (value % 100) / 10
		$Num3.frame_coords.x = value % 10
	elif value >= 1000:
		$Num1.frame_coords.x = 9
		$Num2.frame_coords.x = 9
		$Num3.frame_coords.x = 9
	else:
		print("ERROR: No value applied to moneynumber")
