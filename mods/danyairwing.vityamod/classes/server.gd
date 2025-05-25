extends Node

var vitya
var cfg
var functions = {}

func functions_init():
	cfg = vitya.config
	cfg.handshakes = [] # reset previous handshakes
	functions = {
		#["title", "GRAPHICS"],
		#
		"SERVER":[
			["button", "rejoin", "rejoin"],
			["check", "rejoin on crash", "rj_crash", cfg.rj_crash],
			["check", "rainclouds", "spawn_rainclouds", cfg.spawn_rainclouds],
			 # (column, title, functionality, callable, default, limit)
			#["check", "freecam", "freecam"]
			["title", "lobby creator"],
			["line", "lobby name", "lobby_name"],
			["line", "lobby size", "lobby_playersize", "12", str(cfg.playerlimit)],
			["line", "greet message", "greet_change", "welcome PLAYER, <3", str(cfg.greet)],
			["line", "bye message", "goodbye_change", "goodbye PLAYER, :<", str(cfg.goodbye)],
			["itemlist", "return_lobby_types", "lobby_type_selected", 0],
			["button", "create lobby", "create_lobby"],
			
		],
		
	}
	
	vitya.player_api.connect("player_added", self, "player_joined")
	vitya.player_api.connect("player_leaving", self, "player_leaving")
	
	vitya.utils.connect("new_session", self, "new_session")
	if cfg.rj_crash:
		vitya.utils.join(cfg.lastlobby)
	
var current_lobby_name = ""
var current_lobby_size = ""
var current_lobby_type = 0
var tags = ["talkative", "quiet", "grinding", "chill", "silly", "modded"]
var lobby_types = [
	"Public",
	"Unlisted",
	"Private",
	"Offline"
]

func return_lobby_types(): return lobby_types

func lobby_type_selected(index): current_lobby_type = index

func lobby_playersize(value):
	current_lobby_size = value
func lobby_name(value):
	current_lobby_name = value

func create_lobby():
	Network._create_custom_lobby(int(current_lobby_type), int(current_lobby_size), tags, current_lobby_name, false)
	

func greet_change(value): cfg.greet = value
func goodbye_change(value): cfg.goodbye = value
	
func rejoin(): vitya.utils.rejoin()
	
func handle_handshakes(steamid, data):
	if not "type" in data: return
	if data.type == "vitya":
		var player = vitya.player_api.get_player_from_steamid(steamid)
		if not player in cfg.handshakes:
			cfg.handshakes.append(player)
			vitya.notificate("Handshaked with " + vitya.player_api.get_player_name(player) + ", using Vityamod")
			# TODO: add player icon something idk yet
func handshake(player):
	if player == vitya.utils.lp(): return
	var id = vitya.player_api.get_player_steamid(player)
	var handshake_data = {"steamid": Network.STEAM_ID, "type": "vitya", "status":"handshake"}
	
	Network._send_P2P_Packet(handshake_data, int(id), 2, 39)

func new_session():
	cfg.lastlobby = Network.STEAM_LOBBY_ID
	for player in vitya.player_api.players:
		handshake(player)

	
func player_joined(player):
	handshake(player)
	if is_host():
		var greet = cfg.greet
		if len(greet) < 1:
			greet = greet.replace("PLAYER", vitya.player_api.get_player_name(player))
			Network._send_message(greet, "")
func player_leaving(player):
	if is_host():
		var goodbye = cfg.goodbye
		if len(goodbye) < 1:
			goodbye = goodbye.replace("PLAYER", vitya.player_api.get_player_name(player))
			Network._send_message(goodbye, "")

func is_host(): return Network.GAME_MASTER or Network.PLAYING_OFFLINE
		

func _process_packets():
	if Network.PLAYING_OFFLINE: return
	if not Network.STEAM_ENABLED: return
	
	var packets = Steam.receiveMessagesOnChannel(39, 5)
	for packet in packets:
		var sender = packet["identity"]
		var data = bytes2var(packet.payload)
		handle_handshakes(sender, data)

func spawn_raincloud(pos):
	Network._sync_create_actor("raincloud", pos, "hub_entrance", - 1, Network.STEAM_ID)

func _process(delta):
	var lp = vitya.utils.lp()
	if not lp: return
	var world = lp.world
	var host = is_host()
	if host:
		if cfg.spawn_rainclouds:
			var rainclouds = len(get_tree().get_nodes_in_group("raincloud"))
			if rainclouds <= 1:
				spawn_raincloud(Vector3(63,42,0))
				spawn_raincloud(Vector3(150,42,0)) # these two positions are the most common fishing positions
	_process_packets()
