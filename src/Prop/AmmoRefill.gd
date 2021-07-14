extends Area2D

var refill_sound = load("res://assets/SFX/snd_get_missile.ogg")
var no_sound = load("res://assets/SFX/snd_quote_bonkhead.ogg")

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
	if event.is_action_pressed("inspect") and has_player_near == true and active_player.disabled == false:
		var needed_ammo = false
		
		for w in active_player.weapon_array:
			if w.needs_ammo:
				if w.ammo != w.max_ammo:
					w.ammo = w.max_ammo
					needed_ammo = true
		active_player.get_node("WeaponManager").update_weapon()
		
		if needed_ammo == true:
			$Audio.stream = refill_sound
		else:
			$Audio.stream = no_sound
		$Audio.play()
