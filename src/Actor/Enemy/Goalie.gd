extends Enemy

class_name EnemyGoalie

const ICON = preload("res://assets/Actor/Enemy/GoalieThumbnail.png")

const TX_0 = preload("res://assets/Actor/Enemy/Goalie.png")
const TX_1 = preload("res://assets/Actor/Enemy/Goalie.png")


@onready var BONK = preload("res://src/Effect/BonkParticle.tscn")
@onready var LAND = preload("res://src/Effect/LandParticle.tscn")

@onready var ap = $AnimationPlayer
@onready var kick_hitbox = $KickHitbox
@onready var deflect_hitbox = $DeflectHitbox

var jump_pos: = Vector2.ZERO
## Diff 1: Allow to deflect buttet both from player and enemy
@export var difficulty: int = 0

var kick_force: float = 300.0
var kick_damage: = 4.0

var active_detector_pos = Vector2.ZERO
var jump_detector_pos = Vector2.ZERO
var look_dir: = Vector2.ZERO: set = set_look_dir
var move_dir: = Vector2.ZERO
var target = null
var rise_from_position: = Vector2.ZERO

var player_in_jump_zone: = false
var kicked: = false
var kick_target = null

## Diff 1 related
var kick_next_state: = ""
var allow_to_deflect: bool = false


func set_look_dir(val):
	look_dir = val
	$KickDetector.scale.x = -look_dir.x
	$KickHitbox.scale.x = -look_dir.x
	$ActiveDetector.scale.x = -look_dir.x
	$JumpDetector.scale.x = -look_dir.x
	$Sprite2D.flip_h = look_dir.x > 0.0
	$Hitbox.scale.x = -look_dir.x
	$DeflectDetector.scale.x = -look_dir.x
	$DeflectHitbox.scale.x = -look_dir.x

func setup():
	hp = 4
	damage_on_contact = 2
	speed = Vector2(100, 210)
	gravity = 250

	is_wind_affected = true

	$ActiveDetector/CollisionShape2D.shape.size.y = abs($JumpWaypoint.position.y)
	$ActiveDetector/CollisionShape2D.position.y = -$ActiveDetector/CollisionShape2D.shape.size.y / 2.0
	active_detector_pos = $ActiveDetector.position
	var active_detector_global_pos = $ActiveDetector.global_position
	$ActiveDetector.top_level = true
	$ActiveDetector.global_position = active_detector_global_pos

	$JumpDetector/CollisionShape2D.shape.size.y = abs($JumpWaypoint.position.y) - 32.0
	$JumpDetector/CollisionShape2D.position.y = -$JumpDetector/CollisionShape2D.shape.size.y / 2.0 - 32.0
	jump_detector_pos = $JumpDetector.position
	var jump_detector_global_pos = $JumpDetector.global_position
	$JumpDetector.top_level = true
	$JumpDetector.global_position = jump_detector_global_pos

	match difficulty:
		0:
			$Sprite2D.modulate = Color.WHITE
			$Hurtbox/CollisionShape2D.shape.size = Vector2(11.0, 15.0)
			$Hurtbox/CollisionShape2D.position = Vector2(-0.5, -7.5)
			reward = 3
		1:
			$Sprite2D.modulate = Color(1.0, 0.45, 1.0, 1.0)
			$Hurtbox/CollisionShape2D.shape.size = Vector2(5.0, 15.0)
			$Hurtbox/CollisionShape2D.position = Vector2(-2.5, -7.5)
			reward = 5

	$DeflectDetector.monitoring = difficulty > 0
	$PlayerDetector.monitoring = difficulty > 0
	jump_pos = $JumpWaypoint.global_position
	_setup()
	w.emit_signal("finished_spawn_entities_step")

	change_state("idle")

func _setup():
	pass


### STATE ###
func enter_idle(_prev_state):
	ap.play("Idle")

func do_idle(_delta):
	var player = f.pc()
	if player:
		look_dir.x = signf(player.global_position.x - global_position.x)
	velocity = calc_velocity(Vector2.ZERO)
	move_and_slide()
	update_detector_position()
	if target:
		change_state("active")

func exit_idle(_prev_state):
	pass




func enter_active(_prev_state):
	ap.play("Active")

func do_active(_delta):
	var player = f.pc()
	if player:
		look_dir.x = signf(player.global_position.x - global_position.x)
	velocity = calc_velocity(Vector2.ZERO)
	move_and_slide()
	update_detector_position()
	if !target:
		change_state("idle")
	elif player_in_jump_zone && inp.pressed("jump"):
		change_state("rise")

func exit_active(_prev_state):
	pass



func enter_rise(_prev_state):
	ap.play("Rise")
	am.play("enemy_jump", self)
	move_dir = Vector2.UP
	rise_from_position = global_position

func do_rise(_delta):
	if is_on_ceiling():
		create_effect("Bonk")

	if kick_target and abs(kick_target.global_position.y - global_position.y + 7.0) <= 4.0:
		change_state("kick")

	if is_on_ceiling() || position.y <= jump_pos.y || !target || position.y <= target.global_position.y:
		change_state("fall")
		return

	velocity = calc_velocity(Vector2.UP)
	move_and_slide()
	velocity = velocity

func exit_rise(_prev_state):
	velocity = Vector2.ZERO



func enter_kick(prev_state):
	kicked = true
	ap.play("Kick")
	am.play("enemy_shoot")
	if difficulty == 1:
		if prev_state in ["idle", "active"]:
			kick_next_state = "idle"
		elif prev_state in ["rise", "fall"]:
			kick_next_state = "fall"
	if difficulty == 1:
		deflect_hitbox.set_deferred("monitoring", true)
		deflect_hitbox.set_deferred("monitorable", true)
	kick_hitbox.set_deferred("monitoring", true)
	kick_hitbox.set_deferred("monitorable", true)
	await get_tree().create_timer(0.2).timeout
	kick_hitbox.set_deferred("monitoring", false)
	kick_hitbox.set_deferred("monitorable", false)
	if difficulty == 1:
		deflect_hitbox.set_deferred("monitoring", false)
		deflect_hitbox.set_deferred("monitorable", false)



func do_kick(_delta):
	if not ap.is_playing():
		if difficulty == 1:
			change_state(kick_next_state)
		else:
			change_state("fall")
		return

	velocity = Vector2.ZERO
	move_and_slide()

func exit_kick(_prev_state):
	velocity = Vector2.ZERO
	kick_hitbox.set_deferred("monitoring", false)
	kick_hitbox.set_deferred("monitorable", false)



func enter_fall(_prev_state):
	ap.play("Fall")
	$FallTimer.start()
	if $KickGraceTimer.time_left <= 0.0:
		$KickGraceTimer.start()

func do_fall(_delta):
	velocity = calc_velocity(Vector2.ZERO)
	move_and_slide()
	velocity = velocity

	if kick_target and $KickGraceTimer.time_left > 0.0 and abs(kick_target.global_position.y - global_position.y + 7.0) <= 4.0:
		change_state("kick")

	if is_on_floor() || global_position.y > rise_from_position.y || $FallTimer.time_left <= 0.0:
		am.play("enemy_land", self)
		create_effect("Land")
		change_state("active")
		return

func exit_fall(_prev_state):
	kicked = false

### UTILITY ###
func update_detector_position():
	$ActiveDetector.global_position = global_position + active_detector_pos
	$JumpDetector.global_position = global_position + jump_detector_pos
	jump_pos = $JumpWaypoint.global_position

func set_detector_global(val: bool):
	if val:
		if !$ActiveDetector.top_level:
			var active_detector_global_pos = $ActiveDetector.global_position
			$ActiveDetector.top_level = true
			$ActiveDetector.global_position = active_detector_global_pos

		if !$JumpDetector.top_level:
			var jump_detector_global_pos = $JumpDetector.global_position
			$JumpDetector.top_level = true
			$JumpDetector.global_position = jump_detector_global_pos
	else:
		if $ActiveDetector.top_level:
			var active_detector_local_pos = $ActiveDetector.global_position - global_position
			$ActiveDetector.top_level = false
			$ActiveDetector.position = active_detector_local_pos

		if $JumpDetector.top_level:
			var jump_detector_local_pos = $JumpDetector.global_position - global_position
			$JumpDetector.top_level = false
			$JumpDetector.position = jump_detector_local_pos

func create_effect(vfx_name):
	var last_collision = get_last_slide_collision()
	if last_collision != null:
		match vfx_name:
			"Land":
				#land.global_position = Vector2(global_position.x, last_collision.get_position().y)
				var last_collision_normal = last_collision.get_normal()
				var ray_param: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.new()
				ray_param.from = global_position + Vector2(0.0, -3.0)
				ray_param.to = ray_param.from - last_collision_normal * 5.0
				ray_param.collide_with_bodies = true
				ray_param.collide_with_areas = false
				var world_physics = get_world_2d().direct_space_state
				var result = world_physics.intersect_ray(ray_param)
				if !result.is_empty():
					var land_rotation = last_collision_normal.rotated(PI / 2.0).angle()
					var land = LAND.instantiate()
					land.global_position = result["position"]
					land.rotation = land_rotation
					w.farthest_front.add_child(land)
			"Bonk":
				var bonk = BONK.instantiate()
				bonk.normal = last_collision.get_normal()
				bonk.global_position = last_collision.get_position() + Vector2(0, 16)
				w.farthest_front.add_child(bonk)


### SIGNALS ###
func _on_ActiveDetector_body_entered(body):
	target = body

func _on_ActiveDetector_body_exited(_body):
	target = null


func _on_JumpDetector_body_entered(_body):
	player_in_jump_zone = true
	if state == "active":
		change_state("rise")

func _on_JumpDetector_body_exited(_body):
	player_in_jump_zone = false

func _on_KickDetector_body_entered(body):
	kick_target = body


func _on_KickDetector_body_exited(body: Node2D) -> void:
	kick_target = null


func _on_KickHitbox_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_value(6): #armor
		kick_hitbox.set_deferred("monitoring", false)
		kick_hitbox.set_deferred("monitorable", false)
	elif area.get_collision_layer_value(17): #playerhurt
		area.get_parent().hit(kick_damage, Vector2(80 * look_dir.x, 0), kick_hitbox)
	elif area.get_collision_layer_value(9): #breakable
		if area.name == "BreakArea":
			area.get_parent().on_break("cut")


func _on_KickHitbox_body_entered(body: Node2D) -> void:
	if body.get_collision_layer_value(6): #armor
		kick_hitbox.set_deferred("monitoring", false)
		kick_hitbox.set_deferred("monitorable", false)



func _on_DeflectDetector_body_entered(body: Node2D) -> void:
	if difficulty == 1:
		if state in ["idle", "active"]:
			if body.get_collision_layer_value(7) \
			|| (allow_to_deflect && (body.get_collision_layer_value(14) || body.get_collision_layer_value(2))):
				change_state("kick")


func _on_DeflectHitbox_body_entered(body: Node2D) -> void:
	if body.get_collision_layer_value(7) || (body.get_collision_layer_value(14) && allow_to_deflect):
		var player = f.pc()
		if !player: return
		if body.get_collision_layer_value(7):
			body.change_side(false)
		var dir: = body.global_position.direction_to(player.global_position + Vector2(0, -15))
		body.process_mode = Node.PROCESS_MODE_DISABLED
		body.direction = dir
		body.velocity = dir * kick_force
		await get_tree().physics_frame
		body.process_mode = Node.PROCESS_MODE_INHERIT


func _on_PlayerDetector_body_entered(body: Node2D) -> void:
	allow_to_deflect = true

func _on_PlayerDetector_body_exited(body: Node2D) -> void:
	allow_to_deflect = false
