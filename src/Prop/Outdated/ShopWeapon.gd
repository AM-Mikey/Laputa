extends Area2D


const TOOLTIP = preload("res://src/UI/ShopTooltip.tscn")

@export var gun_name: String
@export var price: int

var get_sound = load("res://assets/SFX/Placeholder/snd_get_item.ogg")
var no_sound = load("res://assets/SFX/Placeholder/snd_quote_bonkhead.ogg")

var gun
var used = false
var has_player_near = false
var active_player = null
var active_tooltip: Node

@onready var ui = get_tree().get_root().get_node("World/UILayer")

func _ready():
	add_to_group("Containers")
	$MoneyNumber.value = price
	$MoneyNumber.display_number()
	
	gun = load("res://src/Gun/%s" % gun_name + ".tres")
	
	$Sprite2D.texture = gun.icon_texture
	$AnimationPlayer.play("DisplayPrice")

func _on_ShopWeapon_body_entered(body):
	if used == false:
		has_player_near = true
		active_player = body
		display_tooltip()
		$AnimationPlayer.play("DisplayNoPrice")

func _on_ShopWeapon_body_exited(_body):
	if used == false:
		has_player_near = false
		if active_tooltip != null:
			active_tooltip.queue_free()
		$AnimationPlayer.play("DisplayPrice")

func display_tooltip():
	var tooltip = TOOLTIP.instantiate()
	tooltip.item_name = gun.display_name
	tooltip.item_description = gun.description
	tooltip.price = price
	add_child(tooltip)
	active_tooltip = tooltip


func _input(event):
	if event.is_action_pressed("inspect") and has_player_near == true and active_player.disabled == false:
		if used == false:
			if active_player.total_xp >= price:
				active_player.total_xp -= price
				used = true
				$AnimationPlayer.play("Used")
				active_tooltip.queue_free()
				$AudioStreamPlayer.stream = get_sound
				$AudioStreamPlayer.play()
				active_player.get_node("GunManager/Guns").add_child(gun)
				active_player.emit_signal("guns_updated", active_player.get_node("GunManager/Guns").get_children())
				print("added gun '", gun_name, "' to inventory")
			else:
				print("not enough money")
				$AudioStreamPlayer.stream = no_sound
				$AudioStreamPlayer.play()
