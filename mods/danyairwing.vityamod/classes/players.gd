extends Node

var vitya
var cfg
var functions = {}

func functions_init():
	cfg = vitya.config
	functions = {
		"PLAYERS": [
		# if itemlist: type, title, func that returns array with items, func on select 
		["itemlist", "playerlist", "player_selected"],
		["itemlist", "actionlist", "action_selected"],
		["viewport", "playermodel", "give_preview_viewport"],
		["button", "commit", "commit_player_action"],
		["button", "revert outfit", "revert_outfit"],
		]
	}
	vitya.utils.connect("new_session", self, "new_session")
func new_session():
	cfg.revert_outfit = PlayerData.cosmetics_equipped


func actionlist(): return player_actionlist
	
func give_preview_viewport():
	var model = preload("res://Scenes/Entities/Player/player.tscn").instance()
	model.dead_actor = true
	model.delete_on_owner_disconnect = false
	cfg.preview_player = model
	return model
func update_preview_player(target_player):

	cfg.preview_player._update_cosmetics(target_player.cosmetic_data)

var player_actionlist = ["teleport to",
		"copy outfit",
		"spectate"]
func spectate(player):
	var lp = vitya.utils.lp()
	if not lp: return
	if lp.cam_orbit_node == player:
		vitya.utils.reset_camera()
		return
	lp.cam_orbit_node = player
	# camera orbit thingy
	# check if already orbitting player reset camera
	
func teleport_to(player):
	var lp = vitya.utils.lp()
	if not lp: return
	if not is_instance_valid(player): return
	
	
	lp.global_transform.origin = player.global_transform.origin + player.transform.basis.x*2
func copy_outfit(player):
	var lp = vitya.utils.lp()
	if not lp: return
	if not is_instance_valid(player): return
	
	PlayerData.cosmetics_equipped = player.cosmetic_data
	lp._change_cosmetics()

	
func playerlist():
	if not vitya.player_api: return []
	var array = []
	for player in vitya.player_api.players:
		if is_instance_valid(player):
			array.append(vitya.player_api.get_player_name(player))
	return array
func player_selected(player):
	cfg.player_selected = player
	update_preview_player(vitya.utils.get_player_from_name(playerlist()[player]))
func action_selected(action):
	cfg.player_action = action
func commit_player_action():
	var playerlist = playerlist()
	if len(playerlist) == 0: return
	var player = vitya.utils.get_player_from_name(playerlist[cfg.player_selected])
	if cfg.player_action == 0: # teleport
		teleport_to(player)
	if cfg.player_action == 1: # copy_outfit
		copy_outfit(player)
	if cfg.player_action == 2: #spectate
		spectate(player)

func revert_outfit():
	var lp = vitya.utils.lp()
	if not lp: return
	var revert = cfg.revert_outfit
	PlayerData.cosmetics_equipped = revert
	lp._change_cosmetics()
