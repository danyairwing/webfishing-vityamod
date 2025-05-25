extends Node

var vitya
var cfg
var functions = {}
func functions_init():
	cfg = vitya.config
	
	vitya.utils.merge_config({
		"skamtebord":false,
		"spin": false,
		"ballspin": false,
		"spinspeed": 1,
		"disable_gravity": false,
		"player_scale": 0,
		"prop_placement": false,
		"death_limit": false,
		"freefly": false,
		"fly_speed": .5
		
	})
	
	functions = {
		"GAMEPLAY":[
		#type, title, function, default*
		["button", "catbark", "catbark"],
		["check", "skamtebord", "skamtebord", cfg.skamtebord],
		["check", "spinbot", "player_spin", cfg.spin],
		["check", "ballspin", "player_ballspin", cfg.ballspin],
		["slider", "spinbot speed", "player_spin_speed", cfg.spinspeed],
		["check", "toggle gravity", "gravity", cfg.disable_gravity],
		["slider", "player scale", "player_scale", cfg.player_scale],
		["slider", "engine timescale", "timescale", .5],
		["check", "prop placement","prop_placement", cfg.prop_placement],
		["check", "no death limit", "death_limit", cfg.death_limit],
		["check", "fly", "freefly", cfg.freefly],
		["slider", "fly speed", "fly_speed", cfg.fly_speed],
		
		["title", "soundmanager"],
		# ["itemlist", "shortcutlist", "shortcut_selected", cfg.open_shortcut],
		["itemlist", "soundmanager_sounds", "sound_selected"], #, cfg.current_sound
		["slider", "pitch", "pitch"], # cfg.sound_pitch
		["button", "play sound", "play_current_sound"]
		
		],
	}
	vitya.utils.connect("new_session", self, "on_new_session")
func on_new_session():
	if cfg.prop_placement:
		prop_placement_on()
	else:
		prop_placement_off()
	
	
func get_sound_manager():
	var lp = vitya.utils.lp()
	if not lp: return
	return lp.get_node("sound_manager")
	
func pitch(value):

	cfg.sound_pitch = value*2
	print(cfg.sound_pitch)
func sound_selected(index):
	var sounds = soundmanager_sounds() 
	var soundname = vitya.utils.array_get(sounds, index)
	cfg.current_sound = soundname
func soundmanager_sounds():
	var lp = vitya.utils.lp()
	if not lp: return []
	var children = get_sound_manager().get_children()
	var names = []
	for i in children: names.append(i.name)
	return names

func play_current_sound():
	if cfg.current_sound:
		var lp = vitya.utils.lp()
		
		if lp:
			lp._sync_sfx(cfg.current_sound, null, cfg.sound_pitch)

func timescale(value):
	value = clamp(value*2, 0.01, 2) # 0.00 points to crashing -- 0.01 is close enough to a paused game (common godot practice)
	Engine.time_scale = value
	

func catbark():
	var lp = vitya.utils.lp()
	if not lp: return
	var current_specie = PlayerData.cosmetics_equipped.species
	var reverse_specie
	if current_specie == "species_dog": 
		# meow
		lp._sync_sfx("bark_cat")
	else: 
		# bark
		lp._sync_sfx("bark_dog")
	
	
	""" # v1.0.0; can while, growl as well
	PlayerData.cosmetics_equipped.species = reverse_specie
	vitya.player_api.local_player._change_cosmetics()
	vitya.player_api.local_player._bark()
	PlayerData.cosmetics_equipped.species = current_specie
	vitya.player_api.local_player._change_cosmetics()
	"""
	

func player_spin_speed(value):
	cfg.spinspeed = value * 30
	

func player_ballspin_on():
	cfg.ballspin = true
	
func player_ballspin_off():
	cfg.ballspin = false
	vitya.utils.reset_camera()
	var lp = vitya.utils.lp()
	if lp:
		lp.rotation = Vector3()
	
func prop_placement_off():
	cfg.prop_placement = false
	var lp = vitya.utils.lp()
	if lp:
		lp.get_node("detection_zones/prop_detect").monitoring = true
	
func prop_placement_on():
	cfg.prop_placement = true
	var lp = vitya.utils.lp()
	if lp:
		lp.get_node("detection_zones/prop_detect").monitoring = false
	
	
func player_spin_on():
	cfg.spin = true
	
func player_spin_off():
	cfg.spin = false
	vitya.utils.reset_camera()
	
func player_scale(scale):
	cfg.player_scale = scale
	
func skamtebord_off():
	cfg.skamtebord = false
	var lp = vitya.utils.lp()
	if lp:
		lp.dive_distance = 9
	
func skamtebord_on():
	cfg.skamtebord = true
	var lp = vitya.utils.lp()
	if lp:
		lp.dive_distance = 21
	
func gravity_off():
	cfg.disable_gravity = false
	
func gravity_on():
	cfg.disable_gravity = true
	
func _process(delta):
	var lp = vitya.utils.lp()
	if not lp: return
	var runtime = vitya.utils.runtime
	#if not lp.get("hud"): return
	
	if cfg.skamtebord:
		lp.dive_distance = 21
		if lp.diving:
			lp.dive_vec = lp.direction*lp.dive_distance

	if cfg.death_limit:
		lp.death_counter = 0
	
	var target_scale = cfg.player_scale*15
	if target_scale == 0: target_scale = 1 # reset to default
	lp["player_scale"] = target_scale
	
	if cfg.spin:
		if lp.cam_orbit_node == null:
			lp.cam_orbit_node = lp
		lp.rotation.y = runtime*cfg.spinspeed
		if lp.diving:
			var targ = -lp.camera.transform.basis.z
			lp.dive_vec = targ*lp.dive_distance
	elif cfg.ballspin:
		if lp.cam_orbit_node == null:
			lp.cam_orbit_node = lp
		lp.rotation.x = runtime*cfg.spinspeed
		lp.rotation.y = runtime*5*cfg.spinspeed
		lp.rotation.z = runtime*5*cfg.spinspeed
	lp.gravity_disable = cfg.disable_gravity
	if cfg.freefly:
		lp.diving = true
		lp.gravity_disable = true
		var up = Input.is_key_pressed(KEY_E)
		var down = Input.is_key_pressed(KEY_Q)
		var target_vel = Vector3()
		var cam_base = lp.cam_base
		if up:
			#add down velocity
			target_vel = cam_base.transform.basis.y
		if down:
			#add up velocity
			target_vel = -cam_base.transform.basis.y
			
		if Input.is_action_pressed("move_forward"): target_vel -= cam_base.transform.basis.z
		if Input.is_action_pressed("move_back"): target_vel += cam_base.transform.basis.z
		if Input.is_action_pressed("move_right"): target_vel += cam_base.transform.basis.x
		if Input.is_action_pressed("move_left"): target_vel -= cam_base.transform.basis.x
		lp.dive_vec = target_vel*delta* clamp(cfg.fly_speed, 0.01,1)*1000 # 10 is flyspeed
			
