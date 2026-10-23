extends Boss

const ICON = preload("res://assets/Icon/BossIcon.png")
const FLARE_BULLET = preload("res://src/Bullet/Enemy/Flare.tscn")

@onready var ap = $AnimationPlayer

var fly_speed: = Vector2(60.0, 60.0)
var look_dir: = Vector2.LEFT:
	set(val):
		look_dir = val
		update_animation()
var move_dir: = Vector2.LEFT
var player_in_close_range := false

func setup():
	hp = 50
	max_hp = 50
	w.emit_signal("finished_spawn_entities_step")

func start_ai():
	sm.change_state("ground")

func keep_grounded(delta: float) -> void:
	velocity.x = 0.0
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y += gravity * delta
	move_and_slide()

func face_player() -> void:
	if pc == null:
		return
	var direction = sign(pc.global_position.x - global_position.x)
	if direction != 0.0:
		look_dir = Vector2(direction, 0.0)

func fire(dir):
	var flare_shot = FLARE_BULLET.instantiate()
	flare_shot.direction = dir
	flare_shot.global_position = $Hotspot/GunNozzle.global_position
	w.player_front.add_child(flare_shot)

func update_animation():
	match look_dir.x:
		-1.0:
			$Sprite2D.flip_h = false
			$Hotspot/GunNozzle.position = Vector2(-13, -19)
		1.0:
			$Sprite2D.flip_h = true
			$Hotspot/GunNozzle.position = Vector2(13, -19)

func _on_PlayerDetector_body_entered(body: Node2D) -> void:
	player_in_close_range = true
	face_player()
	if sm.state in ["ground", "ground_shoot"]:
		sm.change_state("melee")

func _on_PlayerDetector_body_exited(body: Node2D) -> void:
	player_in_close_range = false

func _on_SwingHitbox_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_value(17):
		var knockback_direction = Vector2(look_dir.x * 100.0, 0.0)
		area.get_parent().hit(2, knockback_direction, $SwingHitbox)
