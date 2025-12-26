extends Node

func pc():
	var players = []
	for p in get_tree().get_nodes_in_group("Players"):
		players.append(p)
	if players.size() > 1:
		printerr("ERROR: Multiple nodes found in group 'Players'")
		return null
	elif players.size() == 1:
		return players[0]
	else:
		return null

func hud():
	var huds = []
	for h in get_tree().get_nodes_in_group("HUDs"):
		huds.append(h)
	if huds.size() > 1:
		printerr("ERROR: Multiple nodes found in group 'HUDs'")
		return null
	elif huds.size() == 1:
		return huds[0]
	else:
		return null
