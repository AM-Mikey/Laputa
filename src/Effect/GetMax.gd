extends Node2D

var secondary_started = false

func _ready():
	for p in get_children():
		p.emitting = false
		p.one_shot = true
	$TopLeft.emitting = true
	$TopRight.emitting = true
	$BottomLeft.emitting = true
	$BottomRight.emitting = true
	await get_tree().physics_frame #timer would be too short otherwise
	await get_tree().physics_frame
	await get_tree().physics_frame
	secondary_started = true
	$Top.emitting = true
	$Right.emitting = true
	$Bottom.emitting = true
	$Left.emitting = true

### SIGNALS ###

func _on_Left_finished() -> void:
	if secondary_started:
		queue_free()
