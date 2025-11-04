extends Gun

var clip_size = 7
var clip
var reload_time = 0.5
var fire_time = 0.1
#fires in bursts of 7 bullets. you can fire less but not more before cooldown

func _ready():
	display_name = "Red 7"
	description = "Fires in bursts of Seven. Looks like some kind of prototype."
	icon_texture = load("res://assets/Gun/Red7Icon.png")
	icon_small_texture = load("res://assets/Gun/Red7IconSmall.png")

	sfx = "gun_pistol"
	cooldown_time = 0.1
	automatic = true
	max_ammo = 0
	max_level = 3
	load_level()

func load_level():
	match level:
		1:
			bullet_scene = load("res://src/Bullet/Fan1.tscn")
			clip_size = 3
			damage = 1
			f_range = 60
			speed = 256
			max_xp = 10
		2:
			bullet_scene = load("res://src/Bullet/Fan2.tscn")
			clip_size = 5
			damage = 1
			f_range = 96
			speed = 320
			max_xp = 15
		3:
			bullet_scene = load("res://src/Bullet/Fan3.tscn")
			clip_size = 7
			damage = 1
			f_range = 128
			speed = 384
			max_xp = 20
	clip = clip_size

func activate():
	var bullet = spawn_bullet(get_origin(), pc.shoot_dir)
	bullet.instant_fizzle_check()

	cooldown_time = fire_time
	clip -= 1
	if clip == 0:
		reload()
	else:
		$AutoReload.start(reload_time)


func reload():
	clip = clip_size
	cooldown_time = reload_time

func _on_AutoReload_timeout():
	clip = clip_size
