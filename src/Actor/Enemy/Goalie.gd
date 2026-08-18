extends Enemy

const ICON = preload("res://assets/Actor/Enemy/GoalieThumbnail.png")

const TX_0 = preload("res://assets/Actor/Enemy/Goalie.png")

var jump_pos: = Vector2.ZERO
@export var cooldown_time: = 1.0
var kick_damage: = 4.0

var look_dir: = Vector2.ZERO
var move_dir: = Vector2.ZERO
var target = null
@onready var start_pos: = position



func _ready():
	hp = 4
	damage_on_contact = 1
	speed = Vector2(100, 200)
	gravity = 250

	reward = 3
	is_wind_affected = true

	look_dir = $LookVector.direction.snappedf(1.0)
	$KickDectector.scale.x = -look_dir.x
	$Sprite2D.flip_h = look_dir.x > 0.0

	jump_pos = $JumpWaypoint.global_position
	w.emit_signal("finished_spawn_entities_step")
	change_state("idle")


func _on_ActiveDetector_body_entered(body):
	if $StateMachine.current_state == $StateMachine/Idle:
		$StateMachine.change_state("Active")


func _on_ActiveDetector_body_exited(_body):
	if $StateMachine.current_state == $StateMachine/Active:
		$StateMachine.change_state("Idle")


func _on_JumpDetector_body_entered(_body):
	if $StateMachine.current_state == $StateMachine/Active:
		$StateMachine.change_state("Rise")


func _on_KickDectector_body_entered(body):
	if $StateMachine.current_state == $StateMachine/Rise:
		target = body
		$StateMachine.change_state("Kick")
