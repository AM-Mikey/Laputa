extends Node

const SFX_PLAYER = preload("res://src/Utility/SFX.tscn")

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
	
}

export var remove_duplicates = true
#export var sfx_player_max = 8

var sfx_players = []
var sfx_queue = []



func _ready():
	pass

func play(sfx_string):
	if sfx_dict.has(sfx_string):
		if sfx_queue.has(sfx_string) and remove_duplicates:
			print("WARNING: SFX already playing! Removed SFX with name: " + sfx_string)
			return
		sfx_queue.append(sfx_dict[sfx_string])
		play_sfx(sfx_dict[sfx_string])
	else:
		printerr("ERROR: No SFX with name: " + sfx_string)


func play_sfx(sfx):
	var sfx_player = SFX_PLAYER.instance()
	sfx_players.append(sfx_player)
	add_child(sfx_player)
	
	sfx_player.stream = sfx
	sfx_player.play()
	
	yield(sfx_player, "finished")
	sfx_player.queue_free()
	sfx_queue.erase(sfx)
