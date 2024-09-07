extends Control

var ammo
var max_ammo

func display_ammo():
	if max_ammo == 0:
		visible = false
	else:
		visible = true
	
	if ammo >= 0 and ammo < 10:
		$Num1.visible = false
		$Num2.visible = false
		$Num3.visible = true
		$Num3.frame_coords.x = ammo
	elif ammo >= 10 and ammo < 100:
		$Num1.visible = false
		$Num2.visible = true
		$Num3.visible = true
		$Num2.frame_coords.x = (ammo % 100) / 10
		$Num3.frame_coords.x = ammo % 10
	elif ammo >= 100 and ammo < 1000:
		$Num1.visible = true
		$Num2.visible = true
		$Num3.visible = true
		$Num1.frame_coords.x = (ammo % 1000) / 100
		$Num2.frame_coords.x = (ammo % 100) / 10
		$Num3.frame_coords.x = ammo % 10
	elif ammo >= 1000:
		$Num1.visible = true
		$Num2.visible = true
		$Num3.visible = true
		$Num1.frame_coords.x = 9
		$Num2.frame_coords.x = 9
		$Num3.frame_coords.x = 9
	else:
		printerr("ERROR: hud cannot display current ammo number with value: ", ammo)

	if max_ammo >= 0 and max_ammo < 10:
		$Num4.visible = true
		$Num5.visible = false
		$Num6.visible = false
		$Num4.frame_coords.x = max_ammo
	elif max_ammo >= 10 and max_ammo < 100:
		$Num4.visible = true
		$Num5.visible = true
		$Num6.visible = false
		$Num4.frame_coords.x = (max_ammo % 100) / 10
		$Num5.frame_coords.x = max_ammo % 10
	elif max_ammo >= 100 and max_ammo < 1000:
		$Num4.visible = true
		$Num5.visible = true
		$Num6.visible = true
		$Num4.frame_coords.x = (max_ammo % 1000) / 100
		$Num5.frame_coords.x = (max_ammo % 100) / 10
		$Num6.frame_coords.x = max_ammo % 10
	elif max_ammo >= 1000:
		$Num4.visible = true
		$Num5.visible = true
		$Num6.visible = true
		$Num4.frame_coords.x = 9
		$Num5.frame_coords.x = 9
		$Num6.frame_coords.x = 9
		print("Warning: can't display ammo count higher than 999")
	else:
		printerr("ERROR: hud cannot display max ammo number with value: ", max_ammo)
