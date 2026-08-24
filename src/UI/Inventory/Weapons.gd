class_name Weapons extends Node2D

const STAR_BLANK_TEXTURE = preload("res://assets/UI/Inventory/Items/StarBlank.png") 
const STAR_FULL_TEXTURE = preload("res://assets/UI/Inventory/Items/StarFull.png") 

@onready var pc : Player = f.pc()

@onready var weapon_wheel = %WeaponWheel

@onready var gun_icons = %GunIcons
@onready var gun_sprites = %GunSprites

@onready var weapon_wheel_animator = %WeaponWheelAnimator
@onready var weapon_side_animator = %WeaponSideAnimator

func _ready():
	pc.guns_updated.connect(_on_guns_updated)
	refresh_icons(pc.guns.get_children())

func refresh_icons(guns):
	for i in range(min(guns.size(), 4)):
		gun_icons.get_node(str(i)).texture = guns[i].icon_round_texture
		gun_sprites.get_node(str(i)).texture = guns[i].icon_texture
	
	if guns.size() >= 2:
		gun_icons.get_node("4").texture = guns[-2].icon_round_texture
		gun_sprites.get_node("4").texture = guns[-2].icon_texture
	
	if guns.size() >= 1:
		gun_icons.get_node("5").texture = guns[-1].icon_round_texture
		gun_sprites.get_node("5").texture = guns[-1].icon_texture

func rotate_gun(guns, rot_dir: String):
	match rot_dir:
		"CW":
			weapon_wheel_animator.play("CW")
			weapon_side_animator.play("DOWN")
		"CCW":
			weapon_wheel_animator.play("CCW")
			weapon_side_animator.play("UP")
		#"CCW_Full": #TODO: change this animation to a full rotation to a different gun
				#weapon_wheel_animator.play("CCW", -1, 4.0)
				#weapon_wheel.get_node("Bullet1/Gun").texture = guns[0].icon_texture
				#weapon_wheel.get_node("Bullet2/Gun").texture = guns[1].icon_small_texture
				#if guns.size() >= 3:
					#weapon_wheel.get_node("Bullet3/Gun").texture = guns[2].icon_small_texture
				#if guns.size() >= 4:
					#weapon_wheel.get_node("Bullet4/Gun").texture = guns[-3].icon_small_texture
				#if guns[-2]:
					#weapon_wheel.get_node("Bullet5/Gun").texture = guns[-2].icon_small_texture
				#if guns[-1]:
					#weapon_wheel.get_node("Bullet6/Gun").texture = guns[-1].icon_small_texture
	refresh_icons(guns)


func _on_guns_updated(guns, cause):
	if cause == "shift_left":
		update_weapon_ui(guns, "CCW")
	elif cause == "shift_right":
		update_weapon_ui(guns, "CW")

func update_weapon_ui(guns, rotate_dir):
	rotate_gun(guns, rotate_dir)
	update_weapon_stats(guns)

func update_weapon_stats(guns):
	if guns.size() == 0:
		return

	# Note that index 0 is always the active gun
	var active_gun: Gun = guns[0]

	update_star_count(active_gun.level, active_gun.max_level)
	
	%CooldownLabel.text = str(active_gun.cooldown_time)
	%DamageLabel.text = str(active_gun.damage)
	%MaxAmmoLabel.text = str(active_gun.max_ammo)
	%LifetimeLabel.text = str(active_gun.f_time)
	%RangeLabel.text = str(active_gun.f_range)
	%InventoryHeader.text = active_gun.display_name
	%InventoryBody.text = active_gun.description

	%Lifetime.visible = active_gun.has_lifetime
	%Range.visible = not active_gun.has_lifetime

func update_star_count(gun_level: int, max_level: int):
	var star_groups = {
		1: %OneStar,
		2: %TwoStar,
		3: %ThreeStar,
		4: %FourStar,
		5: %FiveStar,
		6: %SixStar,
	}
	for key in star_groups:
		var group = star_groups[key]

		group.visible = (key == max_level)
		if key == max_level:
			for i in group.get_child_count():
				var star = group.get_child(i)
				star.texture = STAR_FULL_TEXTURE if i < gun_level else STAR_BLANK_TEXTURE
