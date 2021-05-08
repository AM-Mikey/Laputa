extends KinematicBody2D
class_name Actor, "res://assets/Icon/ActorIcon.png"

const DAMAGENUMBER = preload("res://src/Effect/DamageNumber.tscn")
const FLOOR_NORMAL: = Vector2.UP

export var speed: = Vector2(150, 350)
export var gravity: = 300
var _velocity: = Vector2.ZERO

var dead: bool = false

func do_damage_num(recent_damage_taken):
	var num = DAMAGENUMBER.instance()
	get_parent().add_child(num)
	num.position = global_position
	num.value = recent_damage_taken
	num.display_number()
	num.visible = true

	var player = num.get_node("AnimationPlayer")
	player.play("FloatUp")
	yield(player, "animation_finished")
	num.queue_free()
