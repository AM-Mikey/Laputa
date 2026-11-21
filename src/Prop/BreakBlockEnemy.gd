extends PhysicsProp

const ICON = preload("res://assets/Prop/BreakBlockEnemyIcon.png")
const EXPLOSION = preload("res://src/Effect/Explosion.tscn")

var broken = false
var crush_targets = []
var is_grounded = true

@export var break_on_fall = false
@export var has_gravity = true
@export var crush_players = false
@export var crush_enemies = true
@export var squish_enemies = true #enemies this block is pushed into a wall/ceiling
@export var squish_players = true #same for the player (even when crush_players is off)
var crush_min_fall_speed := 40.0 #slower than this (sliding, nudged on a cart) doesn't crush


func setup():
	if !has_gravity:
		$Sprite2D.frame = 3
		base_gravity_scale = 0.0
		water_gravity_scale = 0.0
		gravity_scale = 0.0
	else:
		$Sprite2D.frame = 0
	w.emit_signal("finished_spawn_entities_step")

func on_break(method = "cut"):
	broken = true
	$CollisionShape2D.set_deferred("disabled", true)
	$BreakArea/CollisionShape2D.set_deferred("disabled", true)
	$CrushDetector/CollisionShape2D.set_deferred("disabled", true)
	self.set_deferred("freeze", true)
	am.play("block_break", self)
	var explosion = EXPLOSION.instantiate()
	explosion.global_position = global_position + Vector2(8.0, 8.0)
	w.middle_front.add_child(explosion)

	#rubble never stays on a minecart (or on a stack on one), the cart would roll out from under it
	if $GroundLeft.is_colliding() && $GroundRight.is_colliding() && !rests_on_minecart():
		match method:
			"cut":
				$Sprite2D.frame = 1
			"burn":
				$Sprite2D.frame = 2
	else:
		$Sprite2D.visible = false

	var enemy = load($VUActor.actor_path).instantiate()
	enemy.global_position = $VUActor.global_position
	w.current_level.get_node("Actors").add_child(enemy)


func _physics_process(_delta):
	var supported := !broken && is_supported()
	if !broken:
		if !linear_velocity.y > 50.0 || supported: #riding a cart downhill isn't falling either
			if !is_grounded:
				is_grounded = true
				am.play("block_thud", self)
				if break_on_fall:
					on_break()
		else:
			is_grounded = false
	else:
		is_grounded = true


	if !($GroundLeft.is_colliding() || $GroundRight.is_colliding()) && broken:
		$Sprite2D.visible = false
	#only a block that's actually falling crushes: fast enough, and with nothing under it holding it up
	#(a block riding a cart, falling with a cart, or stacked on another block is held up)
	if !broken && !crush_targets.is_empty() && linear_velocity.y >= crush_min_fall_speed && !supported:
		for t in crush_targets.duplicate():
			crush(t[0], t[1])
			crush_targets.erase(t)
	if !broken:
		squish_pinned($SquishDetector, $CrushDetector, squish_enemies, squish_players)


func crush(type, target):
	if ignore_if_dead_player(target): return
	match type:
		"player":
			if crush_players:
				f.pc().invincible = false
				target.hit(999, Vector2.ZERO, $CrushDetector)
			else:
				on_break()
		"enemy":
			if crush_enemies:
				target.hit(999, Vector2.ZERO, $CrushDetector)
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
