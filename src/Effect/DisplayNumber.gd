extends Node2D

var value: int = -1
var combo_time: float

var player_damage_time = 1.6 #currently iframes are at 1.5
var enemy_damage_time = 0.6
var heart_time = 0.8
var experience_time = 0.8

enum Type {PLAYER_DAMAGE, ENEMY_DAMAGE, HEART, EXPERIENCE}
@export var type : Type

func _ready():
	match type:
		Type.PLAYER_DAMAGE:
			combo_time = player_damage_time
		Type.ENEMY_DAMAGE:
			combo_time = enemy_damage_time
		Type.HEART:
			combo_time = heart_time
		Type.EXPERIENCE:
			combo_time = experience_time
	display_number()
	$AnimationPlayer.play("FloatIn")
	$Timer.start(combo_time)

func reset():
	display_number()
	$AnimationPlayer.play("FloatOut")
	$AnimationPlayer.stop()
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
		printerr("ERROR: No value applied to display number")

func _on_Timer_timeout():
	$AnimationPlayer.play("FloatOut")
	await $AnimationPlayer.animation_finished
	queue_free()
