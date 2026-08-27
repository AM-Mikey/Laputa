extends Enemy

const ICON = preload("res://assets/Actor/Enemy/GoalieThumbnail.png")

const TX_0 = preload("res://assets/Actor/Enemy/Goalie.png")

@onready var BONK = preload("res://src/Effect/BonkParticle.tscn")
@onready var LAND = preload("res://src/Effect/LandParticle.tscn")

var jump_pos: = Vector2.ZERO
@export var cooldown_time: = 1.0

var kick_damage: = 4.0

var look_dir: = Vector2.ZERO
var move_dir: = Vector2.ZERO
var target = null
var target_kick = null

var player_in_active_zone: = false



func _ready():
	hp = 4
	damage_on_contact = 1
	speed = Vector2(100, 200)
	gravity = 250

	reward = 3
	is_wind_affected = true

	look_dir = $LookVector.direction.snappedf(1.0)
	$KickDectector.scale.x = -look_dir.x
	$KickHitbox.scale.x = -look_dir.x

	$ActiveDetector.scale.x = -look_dir.x
	$ActiveDetector/CollisionShape2D.shape.size.y = abs($JumpWaypoint.position.y)
	$ActiveDetector/CollisionShape2D.position.y = -$ActiveDetector/CollisionShape2D.shape.size.y / 2.0
	var active_detector_global_pos = $ActiveDetector.global_position
	$ActiveDetector.top_level = true
	$ActiveDetector.global_position = active_detector_global_pos

	$JumpDetector.scale.x = -look_dir.x
	$JumpDetector/CollisionShape2D.shape.size.y = abs($JumpWaypoint.position.y) - 32.0
	$JumpDetector/CollisionShape2D.position.y = -$JumpDetector/CollisionShape2D.shape.size.y / 2.0 - 32.0
	var jump_detector_global_pos = $JumpDetector.global_position
	$JumpDetector.top_level = true
	$JumpDetector.global_position = jump_detector_global_pos

	$Sprite2D.flip_h = look_dir.x > 0.0

	jump_pos = $JumpWaypoint.global_position
	w.emit_signal("finished_spawn_entities_step")
	change_state("idle")

func create_effect(vfx_name):
	var last_collision = get_last_slide_collision()
	if last_collision != null:
		match vfx_name:
			"Land":
				var land = LAND.instantiate()
				land.global_position = Vector2(global_position.x, last_collision.get_position().y)
				land.rotation = last_collision.get_normal().rotated(PI / 2.0).angle()
				w.front.add_child(land)
			"Bonk":
				var bonk = BONK.instantiate()
				bonk.normal = last_collision.get_normal()
				bonk.global_position = last_collision.get_position() + Vector2(0, 16)
				w.front.add_child(bonk)


func _on_ActiveDetector_body_entered(_body):
	player_in_active_zone = true

func _on_ActiveDetector_body_exited(_body):
	player_in_active_zone = false


func _on_JumpDetector_body_entered(body):
	target = body
	if $StateMachine.current_state == $StateMachine/Active:
		$StateMachine.change_state("Rise")

func _on_JumpDetector_body_exited(_body):
	target = null

func _on_KickDectector_body_entered(_body):
	if $StateMachine.current_state == $StateMachine/Rise:
		$StateMachine.change_state("Kick")
	elif $StateMachine.current_state == $StateMachine/Fall and $KickGraceTimer.time_left > 0.0:
		$StateMachine.change_state("Kick")
