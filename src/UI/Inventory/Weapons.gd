class_name Weapons extends Node2D

@onready var pc : Player = f.pc()


var gun_icon_textures = []
var gun_side_textures = []

@onready var weapon_wheel = %WeaponWheel

@onready var gun_icons = %GunIcons
@onready var gun_sprites = %GunSprites



@onready var weapon_wheel_animator = %WeaponWheelAnimator
@onready var weapon_side_animator = %WeaponSideAnimator

func _ready():
	pc.guns_updated.connect(_on_guns_updated)
	refresh_icons(pc.guns.get_children())
	#[Revolver:<Node2D#378779211848>, Speeder:<Node2D#383476832338>, MPistol:<Node2D#386161186935>, GLauncher:<Node2D#388006680712>, Shotgun:<Node2D#390691035283>, Tsurugi:<Node2D#393023068324>, Red7:<Node2D#395086665908>, Roberta:<Node2D#397334812866>]
func print_children(node: Node) -> void:
	for child in node.get_children():
		print(child)


func refresh_icons(guns):
	gun_icons.get_node("0").texture = guns[0].icon_round_texture
	
	gun_sprites.get_node("0").texture = guns[0].icon_texture
		
	gun_icons.get_node("1").texture = guns[1].icon_round_texture
		
	gun_sprites.get_node("1").texture = guns[1].icon_texture
		
	if guns.size() >= 3:
		gun_icons.get_node("2").texture = guns[2].icon_round_texture
		gun_sprites.get_node("2").texture = guns[2].icon_texture
	if guns.size() >= 4:
		gun_icons.get_node("3").texture = guns[-3].icon_round_texture
		gun_sprites.get_node("3").texture = guns[-3].icon_texture
	if guns[-2]:
		gun_icons.get_node("4").texture = guns[-2].icon_round_texture
		gun_sprites.get_node("4").texture = guns[-2].icon_texture
	if guns[-1]:
		gun_icons.get_node("5").texture = guns[-1].icon_round_texture
		gun_sprites.get_node("5").texture = guns[-1].icon_texture
	
func rotate_gun(guns, rot_dir: String):
	weapon_wheel_animator.play(rot_dir)
	refresh_icons(guns)
	match rot_dir:
		"CW":
			weapon_side_animator.play("DOWN")
		"CWW":
			weapon_side_animator.play("DOWN")
				#weapon_wheel_animator.play("CW", -1, 4.0)
#
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
	update_weapon_stats()

	
func update_weapon_stats():
	var guns = pc.guns
	if guns.get_child_count() == 0:
		return

	# Note that index 0 is always the active gun
	var active_gun: Gun = guns.get_child(0)  

	%CooldownLabel.text = str(active_gun.cooldown_time)
	%DamageLabel.text = str(active_gun.damage)
	%MaxAmmoLabel.text = str(active_gun.max_ammo)
	%LifetimeLabel.text = str(active_gun.f_time)
	%RangeLabel.text = str(active_gun.f_range)
	%InventoryHeader.text = active_gun.display_name
	%InventoryBody.text = active_gun.description
	update_star_count(active_gun.level, active_gun.max_level)
	
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
				group.get_child(i).visible = i < gun_level

func refresh_gun_icon_textures():
	%GunIcons.get_node("0").texture = gun_icon_textures[0]
	%GunIcons.get_node("1").texture = gun_icon_textures[1]
	%GunIcons.get_node("2").texture = gun_icon_textures[2]
	%GunIcons.get_node("3").texture = gun_icon_textures[3]
	%GunIcons.get_node("4").texture = gun_icon_textures[4]
	%GunIcons.get_node("5").texture = gun_icon_textures[5]
	
func refresh_gun_sprite_textures():
	%GunSprites.get_node("0").texture = gun_side_textures[0]
	%GunSprites.get_node("1").texture = gun_side_textures[1]
	%GunSprites.get_node("2").texture = gun_side_textures[2]
	%GunSprites.get_node("3").texture = gun_side_textures[3]
	%GunSprites.get_node("4").texture = gun_side_textures[4]
	%GunSprites.get_node("5").texture = gun_side_textures[5]


func bullets_shift(rot_dir: String):
	if rot_dir == "CWW":
		bullets_shift_left()
		weapon_wheel_animator.play("CWW")
	elif rot_dir == "CW":
		bullets_shift_right()
		weapon_wheel_animator.play("CW")
	
func bullets_shift_left():
	gun_icon_textures.push_front(gun_icon_textures.pop_back())
	refresh_gun_icon_textures()
	#update_weapon_ui()
	
func bullets_shift_right():
	gun_icon_textures.push_back(gun_icon_textures.pop_front())
	refresh_gun_icon_textures()
	#update_weapon_ui()

func side_shift():
	# Note: Currently UP isn't added animated...
	# Also reuse some functionality by creating a cyclicarray 
	# TODO: Fix the one-off shift issue with the guns/bullets, also this is very unclean will have to look a gun order
	weapon_side_animator.play("DOWN")
	gun_side_textures.push_front(gun_side_textures.pop_back())
	refresh_gun_sprite_textures()
	
	for i in range(6):
		var node = %GunSprites.get_node(str(i))
		node.modulate = Color(1, 1, 1) if i == 0 else Color(0.5, 0.5, 0.5)


	
