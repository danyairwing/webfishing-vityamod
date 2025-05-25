extends Node

var vitya
var cfg
var functions = {}
var campfire_lights = []
func functions_init():
	cfg = vitya.config
	vitya.utils.merge_config({
		"spawn_on_click": false,
		"campfire":false,
		"hide_players":false,
		"mouse_spawn_prop": false,
	})
	functions = {
		"WORLD": [
			["check", "campfire lighting", "campfire_light", cfg.campfire],
			["check", "hide players","hide_players", cfg.hide_players],
			["title", "TELEPORT"],
			["button", "void", "goto_void"],
			["button", "hub", "goto_hub"],
			["button", "lobby", "goto_lobby"],
			["button", "aquarium", "goto_aquarium"],
			["title", "CUSTOM TP"],
			["button", "save position", "save_pos"],
			["button", "load position", "load_pos"],
			["title", "prop spawner"],
			["viewport", "prop showcase", "prop_viewmodel"],
			["itemlist", "proplist", "select_prop_id"],
			["check", "spawn on click", "spawn_on_click", cfg.spawn_on_click],
			["button", "spawn", "spawn_prop"],
			["button", "clear props", "clear_props"],
			
		]
		
	}
	vitya.player_api.connect("_player_added", self, "player_added")
	vitya.utils.connect("new_session", self, "new_session")
	vitya.utils.connect("entity_added", self, "entity_added")
	
	
func new_session():
	if cfg.campfire:
		campfire_light_on()
	if cfg.hide_players:
		hide_players_on()
func entity_added(entity):
	if cfg.campfire:
		campfire_prop(entity)

func clear_props():
	var lp = vitya.utils.lp()
	if not lp: return
	for prop in props_id:
		# Network._send_actor_action(actor_id, "_wipe_actor", [id])
		lp._wipe_actor(prop)
		
func select_prop_id(index):
	var prop_name = vitya.utils.array_get(props, index)
	for i in props_viewmodel.get_children():
		if i.name == prop_name:
			i.hidden = false
		else:
			i.hidden = true
	current_selected_prop = prop_name

var props_viewmodel = Spatial.new()
var props_id = []
var current_selected_prop = ""
func prop_viewmodel(): return props_viewmodel

func spawn_prop():
	var lp = vitya.utils.lp()
	if not lp: return
	
	var amt = 0
	for actor in get_tree().get_nodes_in_group("actor"):
		if actor.owner_id == Network.STEAM_ID: amt += 1
	if amt > 32: vitya.notificate("Too many props spawned. New props are not showing globally.", "error")
	
	var pos = lp.global_transform.origin-Vector3(0,0.5,0)
	if cfg.spawn_on_click:
		# TODO: project, raycast
		var camera = lp.camera
		var mousepos = get_viewport().get_mouse_position()/Globals.pixelize_amount # only this function works.
		
		var from = camera.global_transform.origin
		var to_aprox = camera.project_position(mousepos,1)
		var direction = (to_aprox-from).normalized()*2000 
		var to = from + direction
		
		#var to =  from+ direction*200
		var ray = camera.get_world().direct_space_state.intersect_ray(from,to,[lp])
		if len(ray) > 0:
			pos = ray.position
		else:
			return vitya.notificate("Mouse raycast failed.", "error")
	
	if current_selected_prop == "": return vitya.notificate("No prop selected.", "error")
	var prop_file = Globals.item_data[current_selected_prop]["file"]
	
	var new_id = Network._sync_create_actor(prop_file.prop_code, pos, lp.current_zone, - 1, Network.STEAM_ID, Vector3(), lp.current_zone_owner)
	props_id.append(new_id)
	pass # todo: spawn prop which is selected
		
func preload_props():
	var props = []
	for i in Globals.item_data.keys():
		if "prop" in i:
			var file = Globals.item_data[i]["file"]
			print(file)
			var prop = load("res://Scenes/Entities/Props/"+i+".tscn")
			if prop:
				prop = prop.instance()
				props_viewmodel.add_child(prop)
				prop.name = i
				prop.dead_actor = true
				prop.can_be_hidden = true
				prop.hidden = true
				
				props.append(i)
	return props
		
var props = []
func proplist():
	if len(props) == 0:
		props = preload_props()
	return props
	
		
func player_added(player):
	var lp = vitya.utils.lp()
	if cfg.hide_players:
		if player != lp: hide_player(player)
	

func hide_player(player):
	player.can_be_hidden = true
	player.hidden = true
func unhide_player(player):
	player.can_be_hidden = true
	player.hidden = false
func hide_players_on():
	cfg.hide_players = true
	var lp = vitya.utils.lp()
	if lp:
		for player in vitya.player_api.players:
			if player != lp:
				hide_player(player)
	
func hide_players_off():
	cfg.hide_players = false

	var lp = vitya.utils.lp()
	if lp:
		for player in vitya.player_api.players:
			if player != lp:
				unhide_player(player)

func campfire_prop(prop):
	if prop.actor_type == "campfire":
		var light : OmniLight = OmniLight.new()
		prop.add_child(light)
		light.light_color = Color(1,.5,0)
		light.shadow_enabled = false
		light.light_energy = 6
		light.global_transform.origin += Vector3(0,1,0)
		campfire_lights.append(light)




func campfire_light_on():
	cfg.campfire = true
	var entities = vitya.utils.get_all_entities()
	if entities == null: return
	for entity in entities:
		campfire_prop(entity)
func campfire_light_off():
	cfg.campfire = false
	for light in campfire_lights:
		if is_instance_valid(light):
			light.queue_free()
	campfire_lights.clear()



func goto_aquarium():
	var lp = vitya.utils.lp()
	if lp:
		lp._enter_zone("aquarium_zone", "aqua_entrance", -1)
func goto_void():
	var lp = vitya.utils.lp()
	if lp:
		lp._enter_zone("void_zone", "void_entrance", -1)
func goto_hub():
	var lp = vitya.utils.lp()
	if lp:
		lp._enter_zone("hub_building_zone", "hub_entrance", -1)
func goto_lobby():
	var lp = vitya.utils.lp()
	if lp:
		lp._enter_zone("main_zone", "tutorial_spawn", -1)

func save_pos():
	var lp = vitya.utils.lp()
	if lp:
		var pos = lp.global_transform.origin
		cfg.saved_pos = vitya.utils.vectodict(pos)
		var rounded = pos.round()
		vitya.notificate("Saved position:" + str(rounded))
func load_pos():
	var lp = vitya.utils.lp()
	if lp:
		lp.global_transform.origin = vitya.utils.dictovec(cfg.saved_pos)

func _process(delta):
	if cfg.spawn_on_click:
		
		print("spawn on click")
		var mouse_click = Input.is_action_just_pressed("primary_action")
		if mouse_click:
			spawn_prop()
