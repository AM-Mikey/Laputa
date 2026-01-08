extends PhysicsProp

const EXPLOSION = preload("res://src/Effect/Explosion.tscn")

var broken = false
var crush_targets = []
var is_grounded = true

@export var crush_players = false
@export var crush_enemies = true


#func setup():
	#velocity = Vector2.ZERO
	#move_and_slide()

func on_break(method = "cut"):
	broken = true
	$CollisionShape2D.set_deferred("disabled", true)
	$BreakArea/CollisionShape2D.set_deferred("disabled", true)
	$CrushDetector/CollisionShape2D.set_deferred("disabled", true)
	freeze = true
	am.play("block_break", self)
	var explosion = EXPLOSION.instantiate()
	explosion.global_position = global_position + Vector2(8.0, 8.0)
	w.front.add_child(explosion)

	if $GroundLeft.is_colliding() && $GroundRight.is_colliding():
		match method:
			"cut":
				$Sprite2D.frame = 1
			"burn":
				$Sprite2D.frame = 2
	else:
		$Sprite2D.visible = false


func _physics_process(delta):
	if !broken:
		if !linear_velocity.y > 50.0:
			if !is_grounded:
				is_grounded = true
				am.play("block_thud", self)
		else:
			is_grounded = false
	else:
		is_grounded = true


	if !($GroundLeft.is_colliding() || $GroundRight.is_colliding()) && broken:
		$Sprite2D.visible = false
	if linear_velocity.length_squared() > 1.0 && !broken && !crush_targets.is_empty():
		for t in crush_targets:
			crush(t[0], t[1])
			print("BreakBlock Crushed", t)
			crush_targets.erase(t)


func crush(type, target):
	match type:
		"player":
			if crush_players:
				f.pc().invincible = false
				target.hit(999, Vector2.ZERO)
			else:
				on_break()
		"enemy":
			if crush_enemies:
				target.hit(999, Vector2.ZERO)
			else:
				on_break()


### SIGNALS ###

func _on_CrushDetector_body_entered(body): #TODO: other crush interactions
	var target
	if body.get_collision_layer_value(1):
		target = ["player", body.get_parent()]
		if !crush_targets.has(target):
			crush_targets.append(target)
	elif body.get_collision_layer_value(2):
		target = ["enemy", body]
		if !crush_targets.has(target):
			crush_targets.append(target)


func _on_CrushDetector_body_exited(body):
	var target
	if body.get_collision_layer_value(1):
		target = ["player", body.get_parent()]
		crush_targets.erase(target)
	elif body.get_collision_layer_value(2):
		target = ["enemy", body]
		crush_targets.erase(target)
