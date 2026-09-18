extends EnemyGoalie

## Specialized Goalie that can also kick Roller
@onready var SPARK = preload("res://src/Effect/Spark.tscn")

func setup() -> void:
	difficulty = 1
	super.setup()
	$Sprite2D.modulate = Color.GREEN
	$DeflectDetector.set_collision_mask_value(2, true)
	deflect_hitbox.set_collision_mask_value(2, true)

### SIGNALS ###
func _on_DeflectHitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Roller") && body.get_collision_layer_value(2) && allow_to_deflect: #enemy
		var player = f.pc()
		if !player: return
		var dir: = body.global_position.direction_to(player.global_position + Vector2(0, -15))
		#print("Kick: ", body, ": ", body.global_position, " -> ", player.global_position, " = ", dir)
		var knockback = dir * kick_force * 2.0
		#print("Knockback: ",  knockback)
		body.knockback_velocity = knockback
		body.move_dir.x = 1.0 if dir.x >= 0 else -1.0

		var player_distance = body.global_position.distance_to(player.global_position)
		var shake_pixels = remap(player_distance, 0, 256, 8.0, 0.0)
		shake_pixels = clampf(shake_pixels, 0.0, 16)
		player.get_node("PlayerCamera").shake(shake_pixels, 0.2, 8.0)
		am.play("bullet_destroy", body, null, 6.0, 0.2)
		var land_rotation = dir.rotated(PI / 2.0).angle()
		var land = LAND.instantiate()
		land.global_position = body.global_position
		land.rotation = land_rotation
		land.scale.x = 1.0
		w.farthest_front.add_child(land)
		var land_lifetime: = 0.2
		var land_tween = land.create_tween().set_parallel()
		land_tween.tween_property(land, "scale:x", 2.0, land_lifetime)
		land_tween.tween_property(land, "scale:y", 2.0, land_lifetime)
		land_tween.tween_property(land, "global_position", body.global_position - dir * 10.0, land_lifetime)
		var spark = SPARK.instantiate()
		spark.global_position = body.global_position
		w.farthest_front.add_child(spark)
	else:
		super._on_DeflectHitbox_body_entered(body)

func _on_PlayerDetector_body_entered(body: Node2D) -> void:
	allow_to_deflect = true

func _on_PlayerDetector_body_exited(body: Node2D) -> void:
	allow_to_deflect = false
