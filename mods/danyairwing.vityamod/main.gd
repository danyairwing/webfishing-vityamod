extends Node
const config_directory =  "user://vityacfg.cfg" #"mod://vityacfg.cfg"
const version = "v1.1.2"

signal popup_choise

var status_bar_update_timer
var player_api
var keybinds_api
var utils
var ui
var main_window
var popup_window
var statusbar
var exit_button
var drag_bars = []
var mouse_position = Vector2()
var theme : Theme
var examples = {}
var classes = {}
var container_layer = "Panel/container"

"""
"chat_keep_history":false,
	"prop_placement":false,
	"death_limit":false,
	#"chat_lmb_selection":false,
	"hide_players":false,
	"rainbow_accent":false,
	"rainbow_bg":false,
	"rainbow_speed":1,
	"current_sound":null,
	"sound_pitch":.5,
	"handshakes":[],
	"revert_outfit":[],
	"bg":[0,0,0],
	"accent":[0,0,0],
	"statusbar":true,
	"transition":false,
	"skamtebord":false,
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
	"freefly":false,
	"fly_speed":0.01,
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
"""

var config = {
	
}

onready var class_sources = {
	"players":load("res://mods/danyairwing.vityamod/classes/players.gd"),
	"gameplay":load("res://mods/danyairwing.vityamod/classes/gameplay.gd"),
	"hud":load("res://mods/danyairwing.vityamod/classes/hud.gd"),
	"world":load("res://mods/danyairwing.vityamod/classes/world.gd"),
	"server":load("res://mods/danyairwing.vityamod/classes/server.gd"),
}


var notif_sound : AudioStreamPlayer
var world

var github_data = null

func http_data(result, code, header, body):
	github_data = body

func check_version():
	var http_req = HTTPRequest.new()
	add_child(http_req)
	http_req.connect("request_completed", self, "http_data")
	http_req.request("https://api.github.com/repos/danyairwing/webfishing-vityamod/releases/latest")
	while github_data == null:
		yield(get_tree(), "idle_frame")
	print("github data received")
	var newest_version = parse_json(github_data.get_string_from_utf8())["name"]
	if newest_version == version:
		notificate("Running on newest version.")
	else:
		notificate("Running on other version: latest available is " + newest_version, "warn")
	


	
func set_color_list(types, colorname, newcolor):
	for i in types:
		theme.set_color(colorname, i, newcolor)

func get_bg_color():
	return theme.get_color("bg_color", "defaults")
func get_accent_color():
	return theme.get_color("accent_color", "defaults")

func change_accent(new_color):
	
	theme.set_color("accent_color", "defaults", new_color)
	theme.set_color("font_color", "status", new_color)
	theme.get_stylebox("accent", "defaults").bg_color = new_color
	
	var text_color = Color()
	if new_color.v < 0.5: text_color = Color(1,1,1)
	
	set_color_list(["Button"], "font_color_pressed", text_color)
	set_color_list(["ItemList"], "font_color_selected", text_color)
	
func change_bg(new_color):
	theme.get_stylebox("bg", "defaults").bg_color = new_color
	theme.set_color("bg_color", "defaults", new_color)
	
	var text_color = Color()
	if new_color.v < 0.5: text_color = Color(1,1,1)
	
	set_color_list(["Label", "Button", "ItemList"], "font_color", text_color)
	set_color_list(["RichTextLabel"], "default_color", text_color)
	set_color_list(["Button"], "font_color_hover", text_color)
	set_color_list(["LineEdit"], "font_color", text_color)
	set_color_list(["Button"], "font_color_focus", text_color)
func clear_notification_tween(tween, notification):
	tween.queue_free()
	notification.queue_free()
	previous_notif = ""
var previous_notif = ""
func notificate(text, type="default"):
	if previous_notif == text: return
	previous_notif = text
	var tween = Tween.new()
	notif_sound.play() # the sound in question is actually made by me; i've used it since march of 2024 and never published it anywhere. a good change to insert it here! :)  
	
	var notification = clone(examples.notification)
	var showtime = 5
	match type:
		"error": 
			text = "ERROR: " + text
			notification.add_color_override("font_color", Color.red)
			notification.add_color_override("font_color_shadow", Color.black)
			showtime = 12
		"warn":
			text = "WARNING: " + text
			notification.add_color_override("font_color", Color.yellow)
			notification.add_color_override("font_color_shadow", Color.black)
			showtime = 7
		"default":
			text = "[VITYA]: " + text
	
	notification.text = text
	add_child(tween)
	tween.interpolate_property(notification.get_node("Panel"), "anchor_right", 0, 1, .5, Tween.TRANS_BACK)
	tween.interpolate_property(notification, "visible_characters", 0, len(text), .8)
	tween.interpolate_property(notification, "modulate", Color(1,1,1), Color(1,1,1,0), showtime, Tween.TRANS_BACK)
	tween.start()
	tween.connect("tween_all_completed", self, "clear_notification_tween", [tween, notification])

func popup_choise_pressed(choise):
	emit_signal("popup_choise", choise)
	popup_window.visible = false
	
func popup(title, bbtext, choises):
	popup_window.visible = true
	var container = popup_window.get_node("container")
	
	popup_window.text = title
	container.get_node("content").bbcode_text = bbtext
	
	var choises_container = container.get_node("choises")
	
	for ch in choises_container.get_children():
		if ch != examples.choise:
			ch.queue_free()
	
	for choise in choises:
		var choise_button =  clone(examples.choise, choises_container)
		choise_button.text = choise
		choise_button.connect("pressed", self, "popup_choise_pressed", [choise])
	

func clone(node, parent=null, no_children=false):
	if not parent: parent = node.get_parent()
	var cloned = node.duplicate()
	parent.add_child(cloned)
	cloned.visible = true
	if no_children:
		for child in cloned.get_children():
			child.queue_free()
	
	return cloned

func set_keybind(key):
	keybinds_api.register_keybind({
		"action_name":"vitya_toggle",
		"key":key,
	})
	keybinds_api.connect("vitya_toggle", self, "toggle_ui_visibility")
func toggle_ui_visibility():
	if main_window.get_meta("tweening") == true: return
	main_window.set_meta("tweening", true)
	var is_visible = main_window.get_meta("in")
	if is_visible == null: is_visible = true
	is_visible = not is_visible
	main_window.set_meta("in", is_visible)
	
	#main_window.visible = not main_window.visible
	var tween : SceneTreeTween = main_window.create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_parallel(true)
	var tw_time = .5
	
	var offset_scale = get_viewport().size.y*2
	exit_button.visible = is_visible
	if is_visible:
		# visible
		
		
		ui.get_node("Control").mouse_filter = Control.MOUSE_FILTER_STOP
		print("visible")
		tween.tween_property(main_window, "visible", true, 0)
		tween.tween_property(main_window, "self_modulate", Color(0,0,0,0.5), tw_time*2)
		for column in main_window.get_children():
			tween.tween_property(column, "rect_rotation", 0, tw_time)
			tween.tween_property(column, "rect_position", column.rect_position-Vector2(0,offset_scale), tw_time)
			tw_time += 0.01
	else:
		
		ui.get_node("Control").mouse_filter = Control.MOUSE_FILTER_IGNORE
		# not visible
		print("hide")
		randomize()
		tween.tween_property(main_window, "self_modulate", Color(0,0,0,0), tw_time*2)
		for column in main_window.get_children():
			tween.tween_property(column, "rect_rotation", int(rand_range(-1,1)*(randi()%20) ), tw_time)
			tween.tween_property(column, "rect_position", column.rect_position+Vector2(0,offset_scale), tw_time)
			tw_time += 0.01
		tween.set_parallel(false)
		tween.tween_property(main_window, "visible", false, 0)
	tween.play()
	tween.connect("finished", main_window, "set_meta", ["tweening", false])

func set_cfg_slider_value(value, slider, index):
	config[index] = value

func hook_slider(column, text, object, callablename, default):
	var title = create_title(column, text)
	var slider = clone(examples.slider, column.get_node(container_layer))
	title.align = HALIGN_LEFT
	default = float(str(default))
	slider.value = default
	if object.has_method(callablename):
		object.call(callablename, default)
		slider.connect("value_changed", object, callablename)
	else:
		# cfg value
		# config[callablename] = default
		slider.connect("value_changed", self, "set_cfg_slider_value", [slider, callablename])
	
	
	return slider
	
func hook_color(column, title, object, callable, default):
	create_title(column, title)
	
	var color = clone(examples.colorpicker, column.get_node(container_layer))
	color.set_color(object.call(default))
	object.call(callable, color.current_color)
	color.connect("color_changed", object, callable)
	
func check_toggled(check, callableobj, callable):
	
	if check.pressed:
		var on = callable+"_on"
		if not callableobj.has_method(on):
			# probably an cfg value
			config[callable] = true
		else:
			callableobj.call(on)
			
	else:
		var off = callable+"_off"
		if not callableobj.has_method(off):
			# probably an cfg value
			config[callable] = false
		else:
			callableobj.call(off)
			
	
func hook_check(column, text, object, callable, default):
	var check = clone(examples.check, column.get_node(container_layer))
	check.text = text
	check.pressed=default
	check_toggled(check, object, callable)
	
	check.connect("pressed", self, "check_toggled", [check, object, callable])
	
func hook_viewport(column, object, getobj):
	var viewport = clone(examples.viewport, column.get_node(container_layer))
	
	var obj = object.call(getobj)
	
	viewport.set_world(world)
	viewport.set_object(obj)
	
	
func hook_line(column, title, object, callable, placeholder, default):
	create_title(column, title)
	var lineedit = clone(examples.lineedit, column.get_node(container_layer))
	lineedit.placeholder_text = str(placeholder)
	lineedit.text = str(default)
	object.call(callable, default)
	lineedit.connect("text_changed", object, callable)
	
	
func update_itemlist(itemlist : ItemList, object, callable):
	print("list updated.")

	var newlist = object.call(callable)
	var oldlist = []
	
	for item in range(itemlist.get_item_count()):
		
		oldlist.append(itemlist.get_item_text(item))
	
	if len(oldlist) == len(newlist): return #list is same
	
	for i in oldlist:
		if not newlist.has(i): # if item not in new list (player left)
			var index = oldlist.find(i)
			itemlist.remove_item(index)
			oldlist.remove(index)
	for i in newlist:
		if not oldlist.has(i): # if item not in old list (player added)
			itemlist.add_item(i)
	

func hook_itemlist(column, object, getlist, selected,default=null): # in this case title is actually list array:
	var itemlist : ItemList = clone(examples.itemlist, column.get_node(container_layer))
	var timer = Timer.new()
	itemlist.add_child(timer)
	timer.connect("timeout", timer, "start")
	timer.connect("timeout", self, "update_itemlist", [itemlist, object, getlist])
	timer.start()
	
	if default != null:
		update_itemlist(itemlist, object, getlist)
		itemlist.select(default)
		object.call(selected, default)
	
	itemlist.connect("item_selected", object, selected)
func hook_button(column, text, object, callablename): # i hate the fact that 3.5 does not have callables... really feels like it should have that sort of obvious functionality
	var button = clone(examples.button, column.get_node(container_layer))
	
	button.text = text
	button.connect("button_down", object, callablename)
	
	return button
	
	
func create_title(column, text):
	var title = clone(examples.title, column.get_node(container_layer))
	title.text = text
	
	return title
	

func add_bar(bar):
	drag_bars.append(bar)
func remove_bar(bar):
	var index = drag_bars.find(bar)
	bar.rect_rotation = 0
	drag_bars.remove(index)

func create_column(column_title):
	var column_container = examples.column.get_parent()
	var previous_column = column_container.get_child(column_container.get_child_count()-1)
	var previous_column_pos = previous_column.rect_position
	var size =  examples.column.rect_size
	var column = clone(examples.column)
	column.rect_position = Vector2(previous_column_pos.x+size.x,previous_column_pos.y) 
	#var title = create_title(column, column_title)
	column.name = column_title
	
	var bar = column
	bar.connect("button_down", self, "add_bar", [bar])
	bar.connect("button_up", self, "remove_bar", [bar])
	bar.text = column_title
	return column

func load_class(classname, script, initialize=true):
	var functionnode = Node.new()
	
	add_child(functionnode)
	functionnode.set_script(script)
	functionnode.set_process(true)
	functionnode.vitya = self
	functionnode.connect("ready", functionnode, "_ready")
	functionnode.emit_signal("ready")
	# get_tree().connect("idle_frame", functionnode, "_process") #process doesn't connect automatically idk...
	classes[classname] = functionnode
	
	if not initialize: return functionnode
	functionnode.functions_init()
	for column_name in functionnode.functions:
		var column = create_column(column_name)
		for function in functionnode.functions[column_name]:
			var type = utils.array_get(function, 0)
			var title = utils.array_get(function, 1)
			var callable = utils.array_get(function, 2)
			var default = utils.array_get(function, 3)
			var limit = utils.array_get(function, 4)
			if type == "button":
				hook_button(column, title, functionnode, callable)
			if type == "check":
				hook_check(column, title, functionnode, callable, default)
			if type == "title":
				create_title(column, title)
			if type == "slider":
				hook_slider(column, title,functionnode, callable, default) 
			if type == "itemlist":
				hook_itemlist(column, functionnode, title, callable, default) # in this case title is actually list array
			if type == "viewport":
				hook_viewport(column, functionnode, callable)
			if type == "color":
				hook_color(column, title, functionnode, callable, default)
			if type == "line":
				hook_line(column, title, functionnode, callable, default, limit)
	return functionnode
	
func load_ui():
	var ui_instance = load("res://mods/danyairwing.vityamod/scenes/vitya.tscn").instance()
	add_child(ui_instance)
	
	# examples + presets
	ui = ui_instance
	main_window = ui.get_node("Control/vitya")
	popup_window = ui.get_node("Control/popup")
	statusbar = ui.get_node("Control/statusbar")
	exit_button = ui.get_node("Control/exit")
	notif_sound = ui.get_node("notification")
	notif_sound.bus = "SFX"
	theme = ui.get_node("Control").theme
	var font = load("res://Assets/Themes/font_alternate.tres")
	if font:
		theme.default_font = font
	world = load("res://Assets/world_env.tres")
	
	popup_window.connect("button_down", self, "add_bar", [popup_window])
	popup_window.connect("button_up", self, "remove_bar", [popup_window])
	
	examples["notification"] = ui.get_node("Control/notifications/notification")
	examples["choise"] = popup_window.get_node("container/choises/choise")
	
	
	examples["column"] = ui.get_node("Control/vitya/column")
	examples["slider"] = examples.column.get_node(container_layer).get_node("slider")
	examples["title"] = examples.column.get_node(container_layer).get_node("title")
	examples["button"] = examples.column.get_node(container_layer).get_node("button")
	examples["check"] = examples.column.get_node(container_layer).get_node("check")
	examples["itemlist"] = examples.column.get_node(container_layer).get_node("itemlist")
	examples["viewport"] = examples.column.get_node(container_layer).get_node("viewport")
	examples["colorpicker"] = examples.column.get_node(container_layer).get_node("colorpicker")
	examples["lineedit"] = examples.column.get_node(container_layer).get_node("line")
	for example_index in examples:
		var example = examples[example_index]
		example.visible = false
	
func load_config():
	var savedfile = File.new()
	savedfile.open(config_directory, File.READ_WRITE)
	var saved_array = savedfile.get_var()
	savedfile.close()
	if saved_array:
		for index in saved_array:
			var value = saved_array[index]
			config[index] = value
	else:
	
		popup("First launch popup",
		"""
Thanks for downloading Vityamod. We already have 800 downloads! Thank you :>

[b] Use INSERT on your keyboard to close the mod [/b] by default: you can set custom keybinds in the HUD column.

If you have any other issues, join our discord in the same column. [b] Thanks! <3 [/b]

		""", ["Got it!"])
func save_config(): 
	var savedfile = File.new()
	savedfile.open(config_directory, File.WRITE)
	savedfile.store_var(config)
	savedfile.close()
	

func get_journal_fish():
	var caught = 0
	var journal = PlayerData.journal_logs
	for loc_index in journal:
		var loc = journal[loc_index]
		for fish_index in loc:
			var fish_data = loc[fish_index]
			caught += len(fish_data.quality)
	return caught

func get_total_journal_fish():
	var lt = Globals.loot_tables
	var total = 0
	for type in lt:
		var data = lt[type]
		total += len(data.entries)
	return total*5 # including qualities
	
func update_statusbar():
	if statusbar.visible:
		var money = str(PlayerData.money)+"$"
		var time = Time.get_date_string_from_system().replace("-", ".") + " " + Time.get_time_string_from_system() 
		var fish = str(get_journal_fish()) + "/" + str(get_total_journal_fish())
		statusbar.text = (
			"Vityamod " + version
		+ " | " + time
		+ " | " + money 
		+ " | " + fish
		)


func _notification(what):
	if what == NOTIFICATION_CRASH or what == NOTIFICATION_WM_QUIT_REQUEST:
		save_config()

	
func _ready():
	var apimanager = get_node_or_null("/root/BlueberryWolfiAPIs")
	if not apimanager: return # no dependency
	while len(apimanager.modules) < len(apimanager.MODULES_LIST):
		yield(get_tree(), "physics_frame") # waiting apis to load
		
	
	player_api = apimanager.modules["PlayerAPI"]
	keybinds_api = apimanager.modules["KeybindsAPI"]
	
	load_ui()
	utils = load_class("utils", load("res://mods/danyairwing.vityamod/resc/resources/scripts/utils.gd"), false)
	
	#fallbacks
	set_keybind(KEY_INSERT)
	config.bg = utils.colortodic(Color("241f12"))
	config.accent = utils.colortodic(Color("99ad63"))
	
	load_config()
	
	for classname in class_sources:
		var script_class = class_sources[classname]
		load_class(classname, script_class)
		#notificate("Class loaded: " + classname)
	
	# status bar timer
	status_bar_update_timer = Timer.new()
	add_child(status_bar_update_timer)
	status_bar_update_timer.connect("timeout", status_bar_update_timer, "start")
	status_bar_update_timer.connect("timeout", self, "update_statusbar")
	status_bar_update_timer.start()
	update_statusbar()
	
	exit_button.connect("pressed", self, "toggle_ui_visibility")
	
	notificate("Vityamod " + version + " loaded")
	
	check_version()
	
	examples.column.queue_free()
	
	
func _process(delta):
	
	var current_pos = get_viewport().get_mouse_position()
	for bar in drag_bars:
		var relative = current_pos-mouse_position
		bar.rect_position = Vector2(bar.rect_position+relative)
		bar.rect_rotation = lerp(bar.rect_rotation, relative.x/12, 12*delta) 
		
	mouse_position = current_pos
