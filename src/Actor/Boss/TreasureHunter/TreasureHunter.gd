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

func setup():
	hp = 50
	max_hp = 50
	w.emit_signal("finished_spawn_entities_step")

func start_ai():
	sm.change_state("ground")

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
