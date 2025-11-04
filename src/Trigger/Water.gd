extends Trigger

const BUBBLEEMITTER = preload("res://src/Effect/BubbleEmitter.tscn")

var bubble_emitters = {}

func _ready():
	trigger_type = "water"

func _on_Water_body_entered(body):
	var do_bubbles = true
	var target
	if body.get_collision_layer_value(1):
		target = body.get_parent()
	elif body.get_collision_layer_value(2):
		target = body
	elif body.get_collision_layer_value(11) or body.get_collision_layer_value(12) or body.get_collision_layer_value(13):
		target = body
		do_bubbles = false

	active_bodies.append(target)

	if not target.is_in_water:
		target.is_in_water = true
		if do_bubbles:
			var be = BUBBLEEMITTER.instantiate()
			bubble_emitters[target] = be
			target.call_deferred("add_child", be)

		var splash = load("res://src/Effect/Splash.tscn").instantiate()
		splash.position.x = body.global_position.x
		splash.position.y = global_position.y - 4
		get_tree().get_root().get_node("World/Front").add_child(splash)


func _on_Water_body_exited(body):
	var target
	if body.get_collision_layer_value(1):
		target = body.get_parent()
	elif body.get_collision_layer_value(2):
		target = body
	elif body.get_collision_layer_value(11) or body.get_collision_layer_value(12) or body.get_collision_layer_value(13):
		target = body

	if not get_overlap(body):
		target.is_in_water = false
		bubble_emitters[target].queue_free()
		bubble_emitters.erase(target)
	active_bodies.erase(body)
