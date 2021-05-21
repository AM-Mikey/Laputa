extends Area2D

export var weapon_name: String

var get_sound = load("res://assets/SFX/snd_chest_open.ogg")

var weapon
var used = false
var has_player_near = false
var active_player = null

onready var ui = get_tree().get_root().get_node("World/UILayer")

func _ready():
	add_to_group("Container")
	if not used:
		$AnimationPlayer.play("Shine")
	
	weapon = load("res://src/Weapon/%s" % weapon_name + ".tres")
	
func _on_Chest_body_entered(body):
	has_player_near = true
	active_player = body
func _on_Chest_body_exited(body):
	has_player_near = false

func _input(event):
	if event.is_action_pressed("inspect") and has_player_near == true:
		if used == false:
			$AnimationPlayer.play("Used")
			$AudioStreamPlayer.stream = get_sound
			$AudioStreamPlayer.play()
			active_player.weapon_array.push_front(weapon)
			active_player.get_node("WeaponManager").update_weapon()
			print("added weapon '", weapon_name, "' to inventory")
