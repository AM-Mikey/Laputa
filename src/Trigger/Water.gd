extends Trigger

const BUBBLEEMITTER = preload("res://src/Effect/BubbleEmitter.tscn")

var bubble_emitters = {}
var splash_targets = []
@export var velocity_dropoff = 0.75

func _ready():
	trigger_type = "water"

func _on_Water_body_entered(body):
	var do_bubbles = true
	var target
	if body.get_collision_layer_value(1):
		target = body.get_parent()
		target.velocity *= velocity_dropoff
	elif body.get_collision_layer_value(2) or body.get_collision_layer_value(8):
		target = body
		target.velocity *= velocity_dropoff
	elif body.get_collision_layer_value(5) or body.get_collision_layer_value(11) or body.get_collision_layer_value(12) or body.get_collision_layer_value(13):
		target = body
		target.velocity *= velocity_dropoff
		do_bubbles = false
	if !body.get_collision_layer_value(1):
		if target.just_spawned:
			return
	active_bodies.append(target)

	if not target.is_in_water:
		target.is_in_water = true
		if do_bubbles:
			var be = BUBBLEEMITTER.instantiate()
			bubble_emitters[target] = be
			target.call_deferred("add_child", be)

		if !splash_targets.has(target):
			splash_targets.append(target)
			var splash = load("res://src/Effect/Splash.tscn").instantiate()
			splash.position.x = body.global_position.x
			splash.position.y = global_position.y - 4
			get_tree().get_root().get_node("World/Front").add_child(splash)


func _on_Water_body_exited(body):
	var do_bubbles = true
	var target
	if body.get_collision_layer_value(1):
		target = body.get_parent()
	elif body.get_collision_layer_value(2) or body.get_collision_layer_value(8):
		target = body
	elif body.get_collision_layer_value(5) or body.get_collision_layer_value(11) or body.get_collision_layer_value(12) or body.get_collision_layer_value(13):
		target = body
		do_bubbles = false

	if not get_overlap(body):
		target.is_in_water = false
		if do_bubbles and bubble_emitters.has(target):
			bubble_emitters[target].queue_free()
			bubble_emitters.erase(target)
		await get_tree().physics_frame
		if splash_targets.has(target):
			splash_targets.erase(target)
	active_bodies.erase(body)
