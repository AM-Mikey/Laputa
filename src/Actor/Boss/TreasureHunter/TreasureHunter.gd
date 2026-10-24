extends Boss

const ICON = preload("res://assets/Icon/BossIcon.png")
const FLARE_BULLET = preload("res://src/Bullet/Enemy/Flare.tscn")

@onready var ap = $AnimationPlayer

var fly_speed: = Vector2(60.0, 60.0)
var take_off_speed: = 200.0
var ground_rush_speed := 300.0
var look_dir: = Vector2.LEFT:
	set(val):
		look_dir = val
		update_animation()
var move_dir: = Vector2.LEFT
var player_in_close_range := false

var reloading: = false

func setup():
	hp = 50
	max_hp = 50
	w.emit_signal("finished_spawn_entities_step")

func start_ai():
	sm.change_state("ground")

func keep_grounded(delta):
	velocity.x = 0.0
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y += gravity * delta
	move_and_slide()

func fire(dir):
	var flare_shot = FLARE_BULLET.instantiate()
	flare_shot.direction = dir
	flare_shot.global_position = $Hotspot/GunNozzle.global_position
	am.play("boss_treasure_hunter_flare_shot", self, null, 0.0)
	w.player_front.add_child(flare_shot)

func update_animation():
	match look_dir.x:
		-1.0:
			$Sprite2D.flip_h = false
			$Hotspot/GunNozzle.position = Vector2(-13, -19)
		1.0:
			$Sprite2D.flip_h = true
			$Hotspot/GunNozzle.position = Vector2(13, -19)


### UTILITY ###
func face_player():
	if pc == null:
		return
	var direction = sign(pc.global_position.x - global_position.x)
	if direction != 0.0:
		look_dir = Vector2(direction, 0.0)

func get_arena_rect() -> Rect2:
	return w.current_level.get_node("LevelLimiter").get_level_rect()

func get_opposite_arena_side() -> float:
	var arena_rect = get_arena_rect()
	var margin = 24.0
	if global_position.x < arena_rect.get_center().x:
		return arena_rect.end.x - margin
	return arena_rect.position.x + margin

func get_hover_height() -> float:
	var arena_rect = get_arena_rect()
	return arena_rect.position.y + arena_rect.size.y * 0.5

func is_at_x(target_x: float) -> bool:
	return abs(global_position.x - target_x) <= 0.5


### SIGNALS ###
func _on_PlayerDetector_body_entered(_body: Node2D):
	player_in_close_range = true
	face_player()
	if sm.state in ["ground", "ground_shoot"]:
		sm.change_state("melee")

func _on_PlayerDetector_body_exited(_body: Node2D):
	player_in_close_range = false

func _on_SwingHitbox_area_entered(area: Area2D):
	if area.get_collision_layer_value(17):
		var knockback_direction = Vector2(look_dir.x * 100.0, 0.0)
		area.get_parent().hit(2, knockback_direction, $SwingHitbox)
