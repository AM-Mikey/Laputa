extends Prop


const TOOLTIP = preload("res://src/UI/ShopTooltip.tscn")

@export var item_name: String
@export var price: int

var get_sound = load("res://assets/SFX/Placeholder/snd_get_item.ogg")
var no_sound = load("res://assets/SFX/Placeholder/snd_quote_bonkhead.ogg")

var used = false
var has_player_near = false
var active_item
var active_player = null
var active_tooltip: Node


func _ready():
	$MoneyNumber.value = price
	$MoneyNumber.display_number()

	var item_path = "res://src/Item/%s" % item_name + ".tres"
	var item = load(item_path)
	active_item = item
	$Sprite2D.texture = item.texture
	$AnimationPlayer.play("DisplayPrice")

func _on_ShopItem_body_entered(body):
	if used == false:
		has_player_near = true
		active_player = body
		display_tooltip()
		$AnimationPlayer.play("DisplayNoPrice")

func _on_ShopItem_body_exited(_body):
	if used == false:
		has_player_near = false
		if active_tooltip != null:
			active_tooltip.queue_free()
		$AnimationPlayer.play("DisplayPrice")

func display_tooltip():
	var item = active_item
	var tooltip = TOOLTIP.instantiate()
	tooltip.item_name = item.item_name
	tooltip.item_description = item.description
	tooltip.price = price
	add_child(tooltip)
	active_tooltip = tooltip


func _input(event):
	if event.is_action_pressed("inspect") and has_player_near == true and active_player.disabled == false and active_player.can_input:
		if used == false:
			if active_player.money >= price:
				active_player.money -= price
				used = true
				$AnimationPlayer.play("Used")
				active_tooltip.queue_free()
				$AudioStreamPlayer.stream = get_sound
				$AudioStreamPlayer.play()
				active_player.inventory.append(item_name)
				print("added item '", item_name, "' to inventory")
				active_player.update_inventory()
			else:
				print("not enough money")
				$AudioStreamPlayer.stream = no_sound
				$AudioStreamPlayer.play()
