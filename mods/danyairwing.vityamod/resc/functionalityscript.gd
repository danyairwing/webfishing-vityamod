extends Node

var playerapi
var keybindsapi
var vityaself

var config_directory =  "user://vityacfg.cfg" #"mod://vityacfg.cfg"


var hookers = {} # TEEHEEEE A GOOFY VARIABLE NAME?? THATS CRAZY...

var hookerstates = {
	"revert_outfit":[],
	"skamtebord":false,
	"bg":[0.1,0.1,0.1],
	"accent":[1,0,0.5],
	"statusbar":true,
	"disable_gravity":false,
	"pricecatch":false,
	"baitnotif":false,
	"letternotif":false,
	"raincloudnotif":false,
	"campfire":false,
	"spin":false,
	"ballspin":false,
	"spinspeed":0,
	"player_scale":0,
	"freecam":false,
	"saved_pos":[0,0,0],
	"rj_crash":false,
	"lastlobby":-1,
	"player_selected":0,
	"player_action":0,
	"spawn_rainclouds":false,
	
	"preview_player":null,
	"open_shortcut":0,
	
	"greet":"",
	"goodbye":"",
	"playerlimit":12
}

func hookers_init():
	
	# get saved data
	var savedfile = File.new()
	savedfile.open(config_directory, File.READ_WRITE)
	var saved_array = savedfile.get_var()
	savedfile.close()
	if saved_array:
		for index in saved_array:
			var value = saved_array[index]
			hookerstates[index] = value
	else:
		pass #vityaself.notificate("Either the config corrupted, either no config exists.")
	hookers = {
		"HUD": [
		["check", "show price on catch", "pricecatch", hookerstates.pricecatch],
		["check", "status bar", "vitya_status", hookerstates.statusbar],
		["title", "NOTIFICATIONS"],
		["check", "no bait notification", "bait", hookerstates.baitnotif],
		["check", "letter notification", "letter", hookerstates.letternotif],
		["check", "raincloud notification", "raincloud_notification", hookerstates.raincloudnotif],
		["button", "test notifications", "test_notification"],
		["title", "GRAPHICS"],
		["check", "campfire lighting", "campfire_light", hookerstates.campfire],
		["title", "VITYA"],
		["color", "accent color", "accent", "default_accent"],
		["color", "bg color", "bg", "default_bg"],
		["title", "shortcut"],
		["itemlist", "shortcutlist", "shortcut_selected", hookerstates.open_shortcut]
	],
	
	"GAMEPLAY":[
		#type, title, function, default*
		["button", "catbark", "catbark"],
		["check", "skamtebord", "skamtebord", hookerstates.skamtebord],
		["check", "spinbot", "player_spin", hookerstates.spin],
		["check", "ballspin", "player_ballspin", hookerstates.ballspin],
		["slider", "spinbot speed", "player_spin_speed", hookerstates.spinspeed],
		["check", "toggle gravity", "gravity", hookerstates.disable_gravity],
		["slider", "player scale (ratelimited)", "player_scale", hookerstates.player_scale],
		
		["title", "HOST"],
		["button", "rejoin", "rejoin"],
		["check", "rejoin on crash", "rejoin_crash", hookerstates.rj_crash],
		["check", "rainclouds", "toggle_rainclouds", hookerstates.spawn_rainclouds],
		["line", "greet message", "greet_change", "welcome PLAYER, <3", str(hookerstates.greet)],
		["line", "bye message", "goodbye_change", "goodbye PLAYER, :<", str(hookerstates.goodbye)],
		# ["line", "force lobby size", "lobby_playersize", "12", str(hookerstates.playerlimit)]
		 # (column, title, functionality, callable, default, limit)
		#["check", "freecam", "freecam"]
	],
	"TELEPORT":[
		["button", "void", "goto_void"],
		["button", "hub", "goto_hub"],
		["button", "lobby", "goto_lobby"],
		["button", "aquarium", "goto_aquarium"],
		["title", "CUSTOM TP"],
		["button", "save position", "save_pos"],
		["button", "load position", "load_pos"]
		
	],
	"PLAYERS": [
		# if itemlist: type, title, func that returns array with items, func on select 
		["itemlist", "playerlist", "player_selected"],
		["itemlist", "actionlist", "action_selected"],
		["viewport", "playermodel", "give_preview_viewport"],
		["button", "commit", "commit_player_action"],
		["button", "revert outfit", "revert_outfit"],
		
	]
		
	}
	
	if hookerstates.rj_crash:
		join(hookerstates.lastlobby)

func vectodict(vector):
	return [vector.x,vector.y,vector.z]
func dictovec(dict):
	return Vector3(dict[0],dict[1],dict[2])
func colortodic(color):
	return [color.r, color.g, color.b]
func dictocolor(dic):
	return Color(dic[0], dic[1], dic[2])

func revert_outfit():
	var revert = hookerstates.revert_outfit
	PlayerData.cosmetics_equipped = revert
	playerapi.local_player._change_cosmetics()

func get_main():
	return get_tree().root.get_node("/root/world/Viewport/main")

func get_all_entities():
	var main = get_main()
	if main == null: return
	return main.get_node("entities").get_children()

var campfire_lights = []

""" # i wanted to make custom water colors, but ended up with the decision that its kinda.. boring? idk
var water_materials = [
	preload("res://Assets/Shaders/extreme_water_main.tres"),
	preload("res://Assets/Materials/blue.tres"),
	preload("res://Assets/Shaders/extreme_water_alt.tres"),
	preload("res://Assets/Shaders/extreme_water_altc.tres"),
	preload("res://Assets/Shaders/extreme_water_altb.tres"),
	preload("res://Assets/Shaders/waterfall.tres"),
	
	
]
var target_water_color = Color(0,0,0)

func update_water_color():
	for material in water_materials:
		if material is Material:
			if material.get("albedo_color"): material.albedo_color = target_water_color
			else: if material.has_method("set_shader_param"): 
				material.set_shader_param("albedo", target_water_color)
				material.set_shader_param("albedo2", target_water_color)
			print(material)
			#material.set_shader_param("albedo", albedo)
			# material.set_shader_param("albedo2", albedo)

			
"""

func rejoin_crash_on(): hookerstates.rj_crash = true
func rejoin_crash_off(): hookerstates.rj_crash = false

func raincloud_notification_on(): hookerstates.raincloudnotif = true
func raincloud_notification_off(): hookerstates.raincloudnotif = false

func toggle_rainclouds_on():hookerstates.spawn_rainclouds = true
func toggle_rainclouds_off():hookerstates.spawn_rainclouds = false

func join(id):
	if id == -1: return
	get_tree().change_scene("res://Scenes/Menus/Main Menu/main_menu.tscn")
	Network._connect_to_lobby(id)


func rejoin():
	join(Network.STEAM_LOBBY_ID)
	

func default_accent(): return dictocolor(hookerstates.accent) 
func default_bg(): return dictocolor(hookerstates.bg)  

func accent(color):
	vityaself.change_accent(color)
	hookerstates.accent = colortodic(color) 
func bg(color):
	vityaself.change_bg(color) 
	hookerstates.bg = colortodic(color)

func give_preview_viewport():
	var model = preload("res://Scenes/Entities/Player/player.tscn").instance()
	model.dead_actor = true
	model.delete_on_owner_disconnect = false
	hookerstates.preview_player = model
	return model
func update_preview_player(target_player):

	hookerstates.preview_player._update_cosmetics(target_player.cosmetic_data)
func freecam_on():
	pass
func freecam_off():
	pass

func is_host(): return Network.GAME_MASTER or Network.PLAYING_OFFLINE

func save_pos():
	if not is_instance_valid(playerapi.local_player): return
	hookerstates.saved_pos = vectodict(playerapi.local_player.global_transform.origin)
func load_pos():
	if not is_instance_valid(playerapi.local_player): return
	playerapi.local_player.global_transform.origin = dictovec(hookerstates.saved_pos)
var player_actionlist = ["teleport to",
		"copy outfit",
		"spectate"]
		
func actionlist(): return player_actionlist
	
var shortcuts = {
	"insert":KEY_INSERT,
	"f2":KEY_F2,
	"tilda":KEY_QUOTELEFT,
}
	
func shortcutlist():
	return shortcuts.keys()
	
func shortcut_selected(index):
	
	var keycode = shortcuts[vityaself.array_get(shortcuts.keys(), index)]
	hookerstates.open_shortcut = index
	vityaself.set_keybind(keycode)
	
func reset_camera():
	if playerapi.local_player:
		playerapi.local_player.cam_orbit_node = null
	
func spectate(player):
	if playerapi.local_player.cam_orbit_node == player:
		reset_camera()
		return
	playerapi.local_player.cam_orbit_node = player
	# camera orbit thingy
	# check if already orbitting player reset camera
	
func teleport_to(player):
	if not is_instance_valid(player): return
	if not is_instance_valid(playerapi.local_player): return
	playerapi.local_player.global_transform.origin = player.global_transform.origin + player.transform.basis.x*2
func copy_outfit(player):
	if not is_instance_valid(player): return
	if not is_instance_valid(playerapi.local_player): return
	
	PlayerData.cosmetics_equipped = player.cosmetic_data
	playerapi.local_player._change_cosmetics()
func get_player_from_name(playername):
	for player in playerapi.players:
		if is_instance_valid(player):
			var name = playerapi.get_player_name(player)
			if name == playername: return player
	
func playerlist():
	if not playerapi: return []
	var array = []
	for player in playerapi.players:
		if is_instance_valid(player):
			array.append(playerapi.get_player_name(player))
	return array
func player_selected(player):
	hookerstates.player_selected = player
	update_preview_player(get_player_from_name(playerlist()[player]))
func action_selected(action):
	hookerstates.player_action = action
func commit_player_action():
	var playerlist = playerlist()
	if len(playerlist) == 0: return
	var player = get_player_from_name(playerlist[hookerstates.player_selected])
	if hookerstates.player_action == 0: # teleport
		teleport_to(player)
	if hookerstates.player_action == 1: # copy_outfit
		copy_outfit(player)
	if hookerstates.player_action == 2: #spectate
		spectate(player)


func greet_change(value):
	hookerstates.greet = value
func goodbye_change(value):
	hookerstates.goodbye = value
func lobby_playersize(value):
	hookerstates.playerlimit = int(value)

func player_spin_speed(value):
	hookerstates.spinspeed = value * 30

func player_ballspin_on():
	hookerstates.ballspin = true
func player_ballspin_off():
	hookerstates.ballspin = false
	reset_camera()
	if playerapi.local_player:
		playerapi.local_player.rotation = Vector3()
func player_spin_on():
	hookerstates.spin = true
func player_spin_off():
	hookerstates.spin = false
	reset_camera()
func player_scale(scale):
	hookerstates.player_scale = scale

func campfire_prop(prop):
	if prop.actor_type == "campfire":
		var light : OmniLight = OmniLight.new()
		prop.add_child(light)
		light.light_color = Color(1,.5,0)
		light.shadow_enabled = false
		light.light_energy = 6
		light.global_transform.origin += Vector3(0,1,0)
		campfire_lights.append(light)



func vitya_status_on():
	vityaself.statusbar.visible = true
	hookerstates.statusbar = true
func vitya_status_off():
	vityaself.statusbar.visible = false
	hookerstates.statusbar = false


func campfire_light_on():
	hookerstates.campfire = true
	var entities = get_all_entities()
	if entities == null: return
	for entity in entities:
		campfire_prop(entity)
func campfire_light_off():
	hookerstates.campfire = false
	for light in campfire_lights:
		if is_instance_valid(light):
			light.queue_free()
	campfire_lights.clear()

func test_notification():
	vityaself.notificate("we do a little testing")

func letter_inbox():
	if hookerstates.letternotif:
		vityaself.notificate("A new letter in the mail.")
func bait_on():
	hookerstates.baitnotif = true
func bait_off():
	hookerstates.baitnotif = false

func letter_on():
	hookerstates.letternotif = true
func letter_off():
	hookerstates.letternotif = false

func on_dialogue_visibility_changed(dialogue):
	
	if not playerapi.local_player: return
	
	
	
	if not hookerstates.pricecatch: return
	var finder = "You caught a " # bladee reference
	var string = dialogue.bank[0]
	var caught_text = string.find(finder)
	if not caught_text == -1:
		# TODO: lookup the caught fish, check price and add to bank string.
		var item = PlayerData.inventory[len(PlayerData.inventory)-1]
		
		var price = PlayerData._get_item_worth(item["ref"])
		dialogue.get_node("Panel/RichTextLabel").bbcode_text = string.insert(caught_text+len(finder), "[color=#"+Color(0,1,0).to_html()+"]"+ str(price) + "$[/color] ")
		
	

func pricecatch_off():
	hookerstates.pricecatch = false
func pricecatch_on():
	hookerstates.pricecatch = true


func goto_aquarium():
	if is_instance_valid(playerapi.local_player):
		playerapi.local_player._enter_zone("aquarium_zone", "aqua_entrance", -1)
func goto_void():
	if is_instance_valid(playerapi.local_player):
		playerapi.local_player._enter_zone("void_zone", "void_entrance", -1)
func goto_hub():
	if is_instance_valid(playerapi.local_player):
		playerapi.local_player._enter_zone("hub_building_zone", "hub_entrance", -1)
func goto_lobby():
	if is_instance_valid(playerapi.local_player):
		playerapi.local_player._enter_zone("main_zone", "tutorial_spawn", -1)
		
		
func skamtebord_off():
	hookerstates.skamtebord = false
	if is_instance_valid(playerapi.local_player):
		playerapi.local_player.dive_distance = 9
func skamtebord_on():
	hookerstates.skamtebord = true
	if is_instance_valid(playerapi.local_player):
		playerapi.local_player.dive_distance = 21
		
func gravity_off():
	hookerstates.disable_gravity = false
func gravity_on():
	hookerstates.disable_gravity = true
func catbark():
	if not is_instance_valid(playerapi.local_player): return
	var current_specie = PlayerData.cosmetics_equipped.species
	var reverse_specie
	if current_specie == "species_dog": 
		reverse_specie = "species_cat"
	else: 
		reverse_specie = "species_dog"
	
	PlayerData.cosmetics_equipped.species = reverse_specie
	playerapi.local_player._change_cosmetics()
	playerapi.local_player._bark()
	PlayerData.cosmetics_equipped.species = current_specie
	playerapi.local_player._change_cosmetics()


func entity_added(entity):
	if hookerstates.campfire:
		campfire_prop(entity)
	if hookerstates.raincloudnotif:
		if entity.actor_type == "raincloud":
			vityaself.notificate("Raincloud spawned!")

func player_joined(player):
	if is_host():
		var greet = hookerstates.greet
		if len(greet) < 1:
			greet = greet.replace("PLAYER", playerapi.get_player_name(player))
			Network._send_message(greet, "")
func player_leaving(player):
	if is_host():
		var goodbye = hookerstates.goodbye
		if len(goodbye) < 1:
			goodbye = goodbye.replace("PLAYER", playerapi.get_player_name(player))
			Network._send_message(goodbye, "")

func new_session():
	# todo: clear previous stuff, load previous settings if any
	var local_player = playerapi.local_player
	hookerstates.lastlobby = Network.STEAM_LOBBY_ID
	
	
	
	# dialogue
	var dialogue = local_player.hud.get_node("main/dialogue")
	dialogue.connect("visibility_changed", self, "on_dialogue_visibility_changed", [dialogue])
	
	# map entities
	get_main().get_node("entities").connect("child_entered_tree", self, "entity_added")
	if hookerstates.campfire:
		campfire_light_on()
	hookerstates.revert_outfit = PlayerData.cosmetics_equipped

func _ready():
	PlayerData.connect("_letter_update", self, "letter_inbox")
	playerapi.connect("_ingame", self, "new_session")
	playerapi.connect("player_joined", self, "_player_added")
	playerapi.connect("player_leaving", self, "_player_removed")
	

func _notification(what):
	if what == NOTIFICATION_CRASH or what == NOTIFICATION_WM_QUIT_REQUEST:
		var savedfile = File.new()
		savedfile.open(config_directory, File.WRITE)
		savedfile.store_var(hookerstates)
		savedfile.close()

var runtime = 0
func _process(delta):
	runtime += delta
	var local_player = playerapi.local_player
	if not is_instance_valid(local_player): return
	if not local_player.get("hud"): return
	
	if hookerstates.skamtebord:
		local_player.dive_distance = 21
		if local_player.diving:
			local_player.dive_vec = local_player.direction*local_player.dive_distance

	local_player.gravity_disable = hookerstates.disable_gravity
	if hookerstates.baitnotif and PlayerData.bait_selected == "": vityaself.notificate("No bait! Please restock.")
	
	var target_scale = hookerstates.player_scale*15
	if target_scale == 0: target_scale = 1 # reset to default
	local_player["player_scale"] = target_scale
	
	if hookerstates.spin:
		if local_player.cam_orbit_node == null:
			local_player.cam_orbit_node = local_player
		local_player.rotation.y = runtime*hookerstates.spinspeed
		if local_player.diving:
			var targ = -local_player.camera.transform.basis.z
			local_player.dive_vec = targ*local_player.dive_distance
	elif hookerstates.ballspin:
		if local_player.cam_orbit_node == null:
			local_player.cam_orbit_node = local_player
		local_player.rotation.x = runtime*hookerstates.spinspeed
		local_player.rotation.y = runtime*5*hookerstates.spinspeed
		local_player.rotation.z = runtime*5*hookerstates.spinspeed
	
	
	""" # doesn't work value does not overrides.. :<
	if hookerstates.playerlimit > 0:
		Network.SERVER_SETUP_CAP = hookerstates.playerlimit
		Network.WEB_LOBBY_MAX_USERS = hookerstates.playerlimit
	
	if hookerstates.freecam:
		pass #camera control
	"""
	
	
	var world = local_player.world
	var host = is_host()
	if host:
		if hookerstates.spawn_rainclouds:
			if get_tree().get_nodes_in_group("raincloud").size() > 5:
				world._spawn_raincloud()
