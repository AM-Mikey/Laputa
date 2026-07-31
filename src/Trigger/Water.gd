extends Trigger

const BUBBLE_EMITTER = preload("res://src/Effect/BubbleEmitter.tscn")
const PHYS_WATER = preload("res://src/Utility/PhysWater.tscn")
const DROPLET_SPLASH = preload("res://src/Effect/DropletSplash.tscn")

var bubble_emitters = {}
var splash_targets = []
@export var velocity_dropoff = 0.75:
	set(val):
		gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * val
		velocity_dropoff = val

func _ready(): #Reminder: no function called can use await
	trigger_type = "water"
	velocity_dropoff = velocity_dropoff
	var phys_water = PHYS_WATER.instantiate()
	phys_water.water_size = $CollisionShape2D.shape.size
	phys_water.global_position = global_position
	w.current_level.add_child(phys_water) #TODO: put this on a utility layer
	w.emit_signal("finished_spawn_entities_step")

func _on_Water_body_entered(body):
	var do_bubbles = true
	var target
	if body is RigidBody2D: # Use built in Area2D gravity instead.
		return
	if body.get_collision_layer_value(1):
		target = body.get_parent()
		target.velocity *= velocity_dropoff
	elif body.get_collision_layer_value(7) or body.get_collision_layer_value(14): # Bullet
		target = body
		do_bubbles = false
	elif body.get_collision_layer_value(2) or body.get_collision_layer_value(8):
		target = body
		target.velocity *= velocity_dropoff
	elif body.get_collision_layer_value(5) or body.get_collision_layer_value(11) or body.get_collision_layer_value(12) or body.get_collision_layer_value(13):
		target = body
		target.velocity *= velocity_dropoff
		do_bubbles = false
	if !body.get_collision_layer_value(1):
		if $GraceTimer.time_left > 0.0:
			if (!splash_targets.has(target)):
				splash_targets.append(target)
	active_bodies.append(target)

	if not target.is_in_water:
		target.is_in_water = true
		if do_bubbles && target.do_bubbles:
			var be = BUBBLE_EMITTER.instantiate()
			bubble_emitters[target] = be
			target.call_deferred("add_child", be)


		var valid_for_splash = true
		if !splash_targets.has(target):
			if target.has_node("PhysicsLayerBody"):
				valid_for_splash = !target.get_node("PhysicsLayerBody").just_spawned
			var target_check_position_y = target.global_position.y
			if target.has_node("CollisionShape2D"):
				target_check_position_y = min(target_check_position_y, target.get_node("CollisionShape2D").global_position.y)
			valid_for_splash = valid_for_splash && target_check_position_y <= global_position.y + 5.0

		if valid_for_splash:
			splash_targets.append(target)
			var splash = DROPLET_SPLASH.instantiate()
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
	elif body.get_collision_layer_value(7) or body.get_collision_layer_value(14): #Bullet
		target = body
	elif body.get_collision_layer_value(5) or body.get_collision_layer_value(11) or body.get_collision_layer_value(12) or body.get_collision_layer_value(13):
		target = body
		do_bubbles = false

	if not get_overlap(body):
		target.is_in_water = false
		if do_bubbles && bubble_emitters.has(target):
			bubble_emitters[target].queue_free()
			bubble_emitters.erase(target)
		await get_tree().physics_frame
		if splash_targets.has(target):
			splash_targets.erase(target)
	active_bodies.erase(body)
