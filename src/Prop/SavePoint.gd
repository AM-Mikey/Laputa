extends Area2D

var has_player_near = false
var active_player: Node

onready var world = get_tree().get_root().get_node("World")

func _ready():
	$AnimationPlayer.play("Spin")

func _on_SavePoint_body_entered(body):
	has_player_near = true
	active_player = body

func _on_SavePoint_body_exited(body):
	has_player_near = false

func _input(event):
	if event.is_action_pressed("inspect") and has_player_near == true and active_player.disabled == false:
		$AudioStreamPlayer.play()
		world.save_level_data_to_temp()
		world.save_player_data_to_save()
		world.copy_level_data_to_save()
