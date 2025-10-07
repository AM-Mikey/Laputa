extends Resource
class_name Weapon, "res://assets/Icon/WeaponIcon.png"

@export var display_name: String
@export var description # (String, MULTILINE)

@export var texture: CompressedTexture2D
@export var icon_texture: CompressedTexture2D
@export var audio_stream: AudioStream

@export var bullet_scene: PackedScene

@export var damage: int #pass to bullet
@export var projectile_range: int #pass to bullet
@export var projectile_speed: int #pass to bullet

@export var cooldown_time: float
@export var automatic: bool

@export var needs_ammo: bool
@export var ammo: int
@export var max_ammo: int

@export var xp: int = 0
@export var max_xp: int
@export var level: int = 1
@export var max_level: int
