extends Enemy

const ICON = preload("res://assets/Actor/Enemy/GoalieThumbnail.png")

const TX_0 = preload("res://assets/Actor/Enemy/Goalie.png")

@export var jump_height: int = 6
@export var cooldown_time = 1
var kick_damage = 4

var move_dir = Vector2.ZERO
var target = null
@onready var start_pos = position
var jump_pos


func _ready():
	hp = 4
	damage_on_contact = 1
	speed = Vector2(100, 200)
	gravity = 250

	reward = 3
	is_wind_affected = true

	jump_pos = Vector2(position.x, position.y + jump_height * -16)

	w.emit_signal("finished_spawn_entities_step")


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
