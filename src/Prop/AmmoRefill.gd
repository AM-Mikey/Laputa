extends Area2D

var has_player_near = false
var active_player: Node


func _ready():
	#$AnimationPlayer.play("Spin")
	pass

func _on_AmmoRefill_body_entered(body):
	has_player_near = true
	active_player = body

func _on_AmmoRefill_body_exited(body):
	has_player_near = false

func _input(event):
	if event.is_action_pressed("inspect") and has_player_near == true:
		$AudioStreamPlayer.play()
		for w in active_player.weapon_array:
			if w.needs_ammo:
				w.ammo = w.max_ammo
		active_player.get_node("WeaponManager").update_weapon()
