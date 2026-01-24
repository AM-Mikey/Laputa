extends PhysicsProp

const EXPLOSION = preload("res://src/Effect/Explosion.tscn")
const CRYSTAL = preload("res://src/Actor/Pickup/HealthUpgradeCrystal.tscn")

var broken = false
#spent is only triggered when we collect the crystal
var has_left_ground = false
var value := 2

#func setup():
	#velocity = Vector2.ZERO
	#move_and_slide()

func on_break(_method = "cut"): #prevent from breaking midair?
	broken = true
	$CollisionShape2D.set_deferred("disabled", true)
	$BreakArea/CollisionShape2D.set_deferred("disabled", true)
	freeze = true
	am.play("health_upgrade_break", self)
	$AnimationPlayer.play("Break")
	var explosion = EXPLOSION.instantiate()
	explosion.global_position = global_position + Vector2(8.0, 8.0)
	w.back.add_child(explosion)

func spawn_crystal():
	var crystal = CRYSTAL.instantiate()
	crystal.global_position = $CrystalPos.global_position
	crystal.value = value
	crystal.prop_owner = self
	w.middle.add_child(crystal)

func _physics_process(_delta):
	if !broken && !spent:
		if !linear_velocity.y > 50.0:
			if has_left_ground:
				on_break()
		else:
			has_left_ground = true

func expend_prop():
	spent = true
	visible = false

### SIGNALS ###

func _on_AnimationPlayer_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Break":
		visible = false
