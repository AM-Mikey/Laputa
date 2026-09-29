extends "res://src/Actor/Enemy/Goalie.gd"

## Specialized Goalie that can also kick Roller
@onready var SPARK = preload("res://src/Effect/Spark.tscn")
@onready var GOALIE_ROLLER_KICK = preload("res://src/Effect/GoalieRollerKick.tscn")
const roller_kick_force: float = 500.0

func setup() -> void:
	difficulty = 1
	super.setup()
	$Sprite2D.modulate = Color.GREEN
	$DeflectDetector.set_collision_mask_value(2, true)
	deflect_hitbox.set_collision_mask_value(2, true)

### SIGNALS ###
func _on_DeflectDetector_body_entered(body: Node2D) -> void:
	super._on_DeflectDetector_body_entered(body)
	if body.is_in_group("Roller") && body.get_collision_layer_value(2):
		bullet_in_deflect_zone.append(body)

func _on_DeflectHitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Roller") && body.get_collision_layer_value(2): #enemy
		var player = f.pc()
		if !player: return
		var dir: = body.global_position.direction_to(player.global_position + Vector2(0, -15))
		#print("Kick: ", body, ": ", body.global_position, " -> ", player.global_position, " = ", dir)
		var knockback = dir * roller_kick_force
		#print("Knockback: ",  knockback)
		body.knockback_velocity = knockback
		body.gravity_velocity = Vector2.ZERO
		body.move_dir.x = 1.0 if dir.x >= 0 else -1.0

		var player_distance = body.global_position.distance_to(player.global_position)
		var shake_pixels = remap(player_distance, 0, 256, 8.0, 0.0)
		shake_pixels = clampf(shake_pixels, 0.0, 16)
		player.get_node("PlayerCamera").shake(shake_pixels, 0.2, 8.0)
		am.play("bullet_destroy", body, null, 6.0, 0.2)
		var goalie_roller_direction = dir
		var goalie_roller_kick = GOALIE_ROLLER_KICK.instantiate()
		goalie_roller_kick.global_position = body.global_position
		goalie_roller_kick.direction = goalie_roller_direction
		w.farthest_front.add_child(goalie_roller_kick)
		var spark = SPARK.instantiate()
		spark.global_position = body.global_position
		w.farthest_front.add_child(spark)
	else:
		super._on_DeflectHitbox_body_entered(body)
