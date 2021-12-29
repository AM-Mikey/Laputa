extends Node

const SFX_PLAYER = preload("res://src/Utility/SFX.tscn")
const MUSIC_PLAYER = preload("res://src/Utility/Music.tscn")

signal interrupt_finished

export var sfx_dict: Dictionary = {
	"ui_accept": preload("res://assets/SFX/Placeholder/snd_menu_select.ogg"),
	"ui_deny": preload("res://assets/SFX/Placeholder/snd_quote_bonkhead.ogg"),
	"ui_move": preload("res://assets/SFX/Placeholder/snd_menu_move.ogg"),
	
	"door": preload("res://assets/SFX/placeholder/snd_door.ogg"),
	"locked": preload("res://assets/SFX/placeholder/snd_gun_click.ogg"),
	"click": preload("res://assets/SFX/placeholder/snd_gun_click.ogg"),
	"ammo_refill": preload("res://assets/SFX/placeholder/snd_get_missile.ogg"),
	"chest": preload("res://assets/SFX/placeholder/snd_chest_open.ogg"),
	
	"break_block": preload("res://assets/SFX/Placeholder/snd_block_destroy.ogg"),
	"break_grass": preload("res://assets/SFX/Placeholder/snd_explosion2.ogg"),
	
	"save": preload("res://assets/SFX/Placeholder/snd_menu_select.ogg"),
	
	"pc_die": preload("res://assets/SFX/Placeholder/snd_quote_die.ogg"),
	
}

export var music_dict: Dictionary = {
	"get_item": preload("res://assets/Music/Placeholder/Got Item!.ogg"),
	"get_hp": preload("res://assets/Music/Placeholder/Get Heart Tank!.ogg"),
	"gameover": preload("res://assets/Music/Placeholder/Gameover.ogg"),
	"victory": preload("res://assets/Music/Placeholder/Victory!.ogg"),
	
	"none": preload("res://assets/Music/Placeholder/XXXX.ogg"),
	
	"village": preload("res://assets/Music/Placeholder/Mimiga Town.ogg"),
	"access": preload("res://assets/Music/Placeholder/Access.ogg"),
	"safety": preload("res://assets/Music/Placeholder/Safety.ogg"),
	
	"theme": preload("res://assets/Music/Placeholder/laputaintro.ogg"),
}



export var remove_duplicate_sfx = true
export var sfx_player_max = 8
var sfx_players = []
var sfx_queue = []

export var music_player_max = 1
var music_players = []
var music_queue = []

export var interrupt_player_max = 1
var interrupt_players = []
var interrupt_queue = []



func _ready():
	pass

func play(sfx_string):
	if sfx_dict.has(sfx_string):
		if sfx_queue.has(sfx_string) and remove_duplicate_sfx:
			print("WARNING: SFX already playing! Removed SFX with name: " + sfx_string)
			return
		
		var player = add_player("sfx", sfx_string)
		while sfx_players.size() > sfx_player_max:
			clear_player("sfx", player)
		
		yield(player, "finished")
		clear_player("sfx", player)
		
	else:
		printerr("ERROR: No SFX with name: " + sfx_string)


func play_music(music_string):
	if music_dict.has(music_string):
		if music_queue.has(music_string): #don't play if already playing
			return
		
		var player = add_player("music", music_string)
		while music_players.size() > music_player_max:
			clear_player("music", player)
		
		yield(player, "finished")
		clear_player("music", player)
	
	else:
		printerr("ERROR: No music with name: " + music_string)


func play_interrupt(music_string): #play_time, wait_start, wait_end
	for p in music_players: #pause music players
		p.stream_paused = true

	var player = add_player("interrupt", music_string)
	while interrupt_players.size() > interrupt_player_max:
		clear_player("interrupt", player)
	
	yield(player, "finished")
	clear_player("interrupt", player)
	emit_signal("interrupt_finished")
	for p in music_players: #unpause music players
		p.stream_paused = false

#####

func add_player(type, string):
	get(type + "_queue").append(string)
	var player = SFX_PLAYER.instance() if type == "sfx" else MUSIC_PLAYER.instance()
	get(type + "_players").append(player)
	add_child(player)
	player.stream = get(type + "_dict")[string]
	player.play()
	return player

func clear_player(type, player):
		get(type + "_queue").pop_front()
		get(type + "_players").pop_front()
		player.queue_free()

#####

func stop_sfx():
	for p in sfx_players:
		p.queue_free()

func stop_music():
	for p in music_players:
		p.queue_free()
