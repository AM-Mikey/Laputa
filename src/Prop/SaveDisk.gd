extends Node2D

var has_player_near = false
var active_player: Node

onready var world = get_tree().get_root().get_node("World")

func _ready():
	$AnimationPlayer.play("Spin")

func _on_PlayerDetector_body_entered(body):
	has_player_near = true
	active_player = body

func _on_PlayerDetector_body_exited(body):
	has_player_near = false

func _input(event):
	if event.is_action_pressed("inspect") and has_player_near and not active_player.disabled:
		$AudioStreamPlayer.play()
		$AnimationPlayer.playback_speed = 0.5
		world.save_level_data_to_temp()
		world.save_player_data_to_save()
		world.copy_level_data_to_save()
