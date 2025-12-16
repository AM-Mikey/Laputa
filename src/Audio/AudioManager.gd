extends Node

const SFX_PLAYER = preload("res://src/Audio/SFX.tscn")
const POS_SFX_PLAYER = preload("res://src/Audio/PosSFX.tscn")
const MUSIC_PLAYER = preload("res://src/Audio/Music.tscn")

signal interrupt_finished
signal fadeout_finished
signal players_updated

@export var sfx_dict: Dictionary = {
	"sound_test": preload("res://assets/SFX/Placeholder/snd_menu_move.ogg"),
	"ui_accept": preload("res://assets/SFX/Placeholder/snd_menu_select.ogg"),
	"ui_deny": preload("res://assets/SFX/Placeholder/snd_quote_bonkhead.ogg"),
	"ui_move": preload("res://assets/SFX/Placeholder/snd_menu_move.ogg"),

	"door": preload("res://assets/SFX/Placeholder/snd_door.ogg"),
	"locked": preload("res://assets/SFX/Placeholder/snd_gun_click.ogg"),
	"click": preload("res://assets/SFX/Placeholder/snd_gun_click.ogg"),
	"ammo_refill": preload("res://assets/SFX/Placeholder/snd_get_missile.ogg"),
	"chest": preload("res://assets/SFX/Placeholder/snd_chest_open.ogg"),

	"break_block": preload("res://assets/SFX/Placeholder/snd_block_destroy.ogg"),
	"break_grass": preload("res://assets/SFX/Placeholder/snd_explosion2.ogg"),

	"explode": preload("res://assets/SFX/Placeholder/snd_big_crash.ogg"),

	"save": preload("res://assets/SFX/Placeholder/snd_health_refill.ogg"),

	"pc_die": preload("res://assets/SFX/Placeholder/snd_quote_die.ogg"),
	"pc_hurt": preload("res://assets/SFX/Placeholder/snd_quote_hurt.ogg"),
	"pc_jump": preload("res://assets/SFX/Placeholder/snd_quote_jump.ogg"),
	"pc_step": preload("res://assets/SFX/Placeholder/snd_quote_walk.ogg"),
	"pc_bonk": preload("res://assets/SFX/Placeholder/snd_quote_bonkhead.ogg"),
	"pc_land": preload("res://assets/SFX/Placeholder/snd_thud.ogg"),

	"gun_click": preload("res://assets/SFX/Placeholder/snd_gun_click.ogg"),
	"gun_shift": preload("res://assets/SFX/Placeholder/snd_switchweapon.ogg"),
	"gun_pistol": preload("res://assets/SFX/Placeholder/snd_polar_star_l1_2.ogg"),
	"gun_revolver": preload("res://assets/SFX/Placeholder/snd_polar_star_l3.ogg"),
	"gun_shotgun": preload("res://assets/SFX/Placeholder/snd_missile_hit.ogg"),
	"gun_sword": preload("res://assets/SFX/Placeholder/snd_ironh_shot_fly.ogg"),
	"gun_grenade": preload("res://assets/SFX/Placeholder/snd_expl_small.ogg"),
	"gun_grenade_bounce": preload("res://assets/SFX/Placeholder/snd_thud.ogg"),
	"gun_star_bounce": preload("res://assets/SFX/Placeholder/snd_splash.ogg"),

	"bullet_thud": preload("res://assets/SFX/Placeholder/snd_shot_hit.ogg"),
	"bullet_clink": preload("res://assets/SFX/Placeholder/snd_shot_bounce.ogg"),
	"bullet_destroy" : preload("res://assets/SFX/Placeholder/snd_expl_small.ogg"),

	"get_hp": preload("res://assets/SFX/Placeholder/snd_health_refill.ogg"),
	"xp": preload("res://assets/SFX/Placeholder/snd_xp_bounce.ogg"),
	"get_xp": preload("res://assets/SFX/Placeholder/snd_get_xp.ogg"),
	"get_ammo": preload("res://assets/SFX/Placeholder/snd_get_missile.ogg"),

	"level_up": preload("res://assets/SFX/Placeholder/snd_level_up.ogg"),

	"enemy_die": preload("res://assets/SFX/Placeholder/snd_little_crash.ogg"),
	"enemy_jump": preload("res://assets/SFX/Placeholder/snd_critter_jump.ogg"),
	"enemy_croak": preload("res://assets/SFX/FrogCroak.ogg"),
	"enemy_hurt": preload("res://assets/SFX/Placeholder/snd_enemy_hurt.ogg"),
	"enemy_shoot": preload("res://assets/SFX/Placeholder/snd_em_fire.ogg"),
	"enemy_tweet": preload("res://assets/SFX/bird.ogg"),
	#"enemy_buzz":

	"npc_dialog": preload("res://assets/SFX/Placeholder/snd_msg.ogg"),

	"effect_pop": preload("res://assets/SFX/PopSmall.ogg"),
}

@export var music_dict: Dictionary = {
	"sound_test": preload("res://assets/SFX/Placeholder/snd_menu_move.ogg"),
	"get_item": preload("res://assets/Music/Placeholder/Got Item!.ogg"),
	"get_hp": preload("res://assets/Music/Placeholder/Get Heart Tank!.ogg"), #TODO: rename
	"gameover": preload("res://assets/Music/Placeholder/Gameover.ogg"),
	"victory": preload("res://assets/Music/Placeholder/Victory!.ogg"),
	"none": preload("res://assets/Music/Placeholder/XXXX.ogg"),
	"village": preload("res://assets/Music/Placeholder/Mimiga Town.ogg"),
	"access": preload("res://assets/Music/Placeholder/Access.ogg"),
	"safety": preload("res://assets/Music/Placeholder/Safety.ogg"),
	"theme": preload("res://assets/Music/Placeholder/laputaintro.ogg"),

	"shop": preload("res://assets/Music/PhiDelta_Shop.wav"),
	"shop_intro": preload("res://assets/Music/PhiDelta_Shop_Intro.wav"),
	"dogtown_day": preload("res://assets/Music/59Squared_DogtownDay.wav"),
	"dogtown_night": preload("res://assets/Music/59Squared_DogtownNight.wav"),
	"title": preload("res://assets/Music/59Squared_Title.wav"),
	"train_intro": preload("res://assets/Music/59Squared_Train_Intro.wav"),
	"train": preload("res://assets/Music/59Squared_Train_Loop.wav")


}


@export var sfx_player_max = 12
var sfx_queue = []
@export var remove_recent_duplicate_sfx = true
@export var sfx_recent_time = 0.05
var sfx_recent = []

@export var music_player_max = 1
var music_queue = []

@export var interrupt_player_max = 1
var interrupt_queue = []


func play(sfx_string: String, actor = null, bus = null):
	if _check_sfx(sfx_string):
		var player
		if actor == null: #non-positional
			player = _add_player("sfx", sfx_string)
		else: #positional
			player = _add_player("pos", sfx_string, actor)

		if sfx_queue.size() > sfx_player_max:
			print("WARNING: Too many SFX players! Removed first player")
			_clear_player("sfx", sfx_queue.front())

		if bus != null: #non-specific bus
			player.bus = bus

		await player.finished
		var queue_slot = [player, sfx_string]
		_clear_player("sfx", queue_slot)


func play_music(music_string): #TODO: add a resource with track info
	#var track = {
		#"producer" = file_info[0],
		#"name" = file_info[1],
		#"intro" = "",
		#"loop" = loop_path,
		#"outro" = ""
	#}

	var loop = music_string #TODO: implement outro
	var intro = ""
	if music_dict.has(String(music_string + "_intro")) :
		intro = String(music_string + "_intro")


	var now_playing = ""
	var player
	if intro != "":
		player = _add_player("music", intro)
		now_playing = "intro"
	else: #no intro
		player = _add_player("music", loop)
		now_playing = "loop"

	if music_queue.size() > music_player_max:
		_clear_player("music", music_queue.front())

	if now_playing == "intro": #switch to loop
		await player.finished
		var queue_slot = [player, intro]
		_clear_player("music", queue_slot)
		player = _add_player("music", loop)
		now_playing = "loop"



func play_interrupt(music_string):
	pause_music(true)
	var player = _add_player("interrupt", music_string)
	if interrupt_queue.size() > interrupt_player_max:
		_clear_player("interrupt", interrupt_queue.front())
	await player.finished
	var queue_slot = [player, music_string]
	_clear_player("interrupt", queue_slot)
	emit_signal("interrupt_finished")
	pause_music(false)


### ADD AND REMOVE ###

func _add_player(type, audio_string, actor = null):
	var player
	match type:
		"sfx":
			player = SFX_PLAYER.instantiate()
			player.stream = sfx_dict[audio_string]
			add_child(player)
			var queue_slot = [player, audio_string]
			sfx_queue.append(queue_slot)
		"pos":
			player = POS_SFX_PLAYER.instantiate()
			player.stream = sfx_dict[audio_string]
			player.global_position = actor.global_position
			add_child(player)
			var queue_slot = [player, audio_string]
			sfx_queue.append(queue_slot)
		"interrupt":
			player = MUSIC_PLAYER.instantiate()
			player.stream = music_dict[audio_string]
			add_child(player)
			var queue_slot = [player, audio_string]
			interrupt_queue.append(queue_slot)
		"music":
			player = MUSIC_PLAYER.instantiate()
			player.stream = music_dict[audio_string]
			add_child(player)
			var queue_slot = [player, audio_string]
			music_queue.append(queue_slot)
	player.play()
	emit_signal("players_updated")
	return player


func _clear_player(type, queue_slot):
	match type:
		"sfx", "pos":
			sfx_queue.erase(queue_slot)
		"music":
			music_queue.erase(queue_slot)
		"interrupt":
			interrupt_queue.erase(queue_slot)
	queue_slot[0].queue_free() #player
	emit_signal("players_updated")

### CONTROLS ###
func stop_sfx():
	for s in sfx_queue:
		s[0].queue_free()
		emit_signal("players_updated")

func stop_music():
	for s in music_queue:
		s[0].queue_free()
		emit_signal("players_updated")

func pause_music(pause = true):
	for s in music_queue:
		s[0].stream_paused = pause

func fade_music(duration = 1.0):
	if music_queue.is_empty():
		return
	var player = music_queue.front()[0]
	var tween = get_tree().create_tween()
	tween.tween_property(player, "volume_db", -80, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	_clear_player("music", music_queue.front())
	emit_signal("fadeout_finished")

var attenuate_music: bool = false
func underwater_attenuate(val: bool):
	var audio_bus_music_idx: int = AudioServer.get_bus_index("Music")
	var audio_bus_sfx_idx: int = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_effect_enabled(audio_bus_music_idx, 0, val and attenuate_music) #LowPassFilter
	AudioServer.set_bus_effect_enabled(audio_bus_music_idx, 1, val and attenuate_music) #Reverb
	AudioServer.set_bus_effect_enabled(audio_bus_sfx_idx, 0, val) #LowPassFilter
	AudioServer.set_bus_effect_enabled(audio_bus_sfx_idx, 1, val) #Reverb


### GETTERS ###

func _check_sfx(sfx_string) -> bool:
	if not sfx_dict.has(sfx_string):
		printerr("ERROR: No SFX with name: " + sfx_string)
		return false

	if remove_recent_duplicate_sfx:
		if sfx_recent.has(sfx_string):
			print("WARNING: SFX already playing! Removed SFX with name: " + sfx_string)
			return false
		else:
			_do_recent_time(sfx_string)
	return true

func _do_recent_time(sfx_string):
	sfx_recent.append(sfx_string)
	await get_tree().create_timer(sfx_recent_time).timeout
	sfx_recent.erase(sfx_string)
