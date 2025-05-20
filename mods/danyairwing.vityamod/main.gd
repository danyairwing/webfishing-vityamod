extends Node

var player_api
var keybinds_api
var ui
var main_window
var statusbar
var moving_window = false
var mouse_position = Vector2()
var theme : Theme
var examples = {}
var functionality = preload("res://mods/danyairwing.vityamod/resc/functionality.tscn")
var notif_sound : AudioStreamPlayer
var world

func array_get(array:Array, index):
	var dict = {}
	var x = 0
	for v in array:
		dict[x] = v
		x += 1
		
	var p = dict.get(index)
	dict.empty()
	return p

func get_all_children(node):
	var nodes : Array = []
	for N in node.get_children():
		if N.get_child_count() > 0:
			nodes.append(N)
			nodes.append_array(get_all_children(N))
		else:
			nodes.append(N)
	return nodes

	
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
func change_bg(new_color):
	theme.get_stylebox("bg", "defaults").bg_color = new_color
	theme.set_color("bg_color", "defaults", new_color)
	var text_color = Color()
	if new_color.v < 0.5: text_color = Color(1,1,1)
	set_color_list(["Label", "Button", "ItemList"], "font_color", text_color)
	set_color_list(["Button"], "font_color_hover", text_color)
	set_color_list(["Button"], "font_color_focus", text_color)
func clear_notification_tween(tween, notification):
	tween.queue_free()
	notification.queue_free()
	previous_notif = ""
var previous_notif = ""
func notificate(text):
	if previous_notif == text: return
	var tween = Tween.new()
	notif_sound.play() # the sound in question is actually made by me; i've used it since march of 2024 and never published it anywhere. a good change to insert it here! :)  
	
	var notification = clone(examples.notification)
	notification.text = text
	previous_notif = text
	add_child(tween)
	tween.interpolate_property(notification, "modulate", Color(1,1,1), Color(1,1,1,0), 5, Tween.TRANS_BACK)
	tween.start()
	tween.connect("tween_all_completed", self, "clear_notification_tween", [tween, notification])

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
	main_window.visible = not main_window.visible

func hook_slider(column, text, object, callablename, default):
	var title = create_title(column, text)
	var slider = clone(examples.slider, column.get_node("ScrollContainer/container"))
	title.align = HALIGN_LEFT
	slider.value = default
	object.call(callablename, default)
	slider.connect("value_changed", object, callablename)
	
	
	return slider
	
func hook_color(column, title, object, callable, default):
	create_title(column, title)
	
	var color = clone(examples.colorpicker, column.get_node("ScrollContainer/container"))
	color.set_color(object.call(default))
	object.call(callable, color.current_color)
	color.connect("color_changed", object, callable)
	
func check_toggled(check, callableobj, callable):
	if check.pressed:
		callableobj.call(callable+"_on")
	else:
		callableobj.call(callable+"_off")
	
func hook_check(column, text, object, callable, default):
	var check = clone(examples.check, column.get_node("ScrollContainer/container"))
	check.text = text
	check.pressed=default
	check_toggled(check, object, callable)
	
	check.connect("pressed", self, "check_toggled", [check, object, callable])
	
func hook_viewport(column, object, getobj):
	var viewport = clone(examples.viewport, column.get_node("ScrollContainer/container"))
	
	var obj = object.call(getobj)
	
	viewport.get_node("Viewport/WorldEnvironment").environment = world
	
	viewport.get_node("Viewport").add_child(obj)
	obj.global_transform.origin = Vector3()
	var camera = viewport.get_node("Viewport/Camera")
	camera.global_transform.origin = -obj.transform.basis.z*5 + Vector3(5,2,0)
	camera.look_at(Vector3(), Vector3.UP)
	
func hook_line(column, title, object, callable, placeholder, default):
	create_title(column, title)
	var lineedit = clone(examples.lineedit, column.get_node("ScrollContainer/container"))
	lineedit.placeholder_text = placeholder
	lineedit.text = default
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
	var itemlist : ItemList = clone(examples.itemlist, column.get_node("ScrollContainer/container"))
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
	var button = clone(examples.button, column.get_node("ScrollContainer/container"))
	
	button.text = text
	button.connect("button_down", object, callablename)
	
	return button
	
	
func create_title(column, text):
	var title = clone(examples.title, column.get_node("ScrollContainer/container"))
	title.text = text
	
	return title
	
func create_column(column_title):
	var column = clone(examples.column)
	var title = create_title(column, column_title)
	
	return column
func load_ui():
	var ui_instance = load("res://mods/danyairwing.vityamod/scenes/vitya.tscn").instance()
	add_child(ui_instance)
	
	# examples + presets
	ui = ui_instance
	main_window = ui.get_node("Control/vitya")
	statusbar = ui.get_node("Control/statusbar")
	notif_sound = ui.get_node("notification")
	notif_sound.bus = "SFX"
	theme = ui.get_node("Control").theme
	var font = load("res://Assets/Themes/font_alternate.tres")
	if font:
		theme.default_font = font
	world = load("res://Assets/world_env.tres")
	
	
	examples["column"] = ui.get_node("Control/vitya/container/column")
	examples["title"] = ui.get_node("Control/vitya/container/column/ScrollContainer/container/titleexample")
	examples["button"] = ui.get_node("Control/vitya/container/column/ScrollContainer/container/Button")
	examples["check"] = ui.get_node("Control/vitya/container/column/ScrollContainer/container/CheckButton")
	examples["notification"] = ui.get_node("Control/notifications/notification")
	examples["slider"] = ui.get_node("Control/vitya/container/column/ScrollContainer/container/HSlider")
	examples["itemlist"] = ui.get_node("Control/vitya/container/column/ScrollContainer/container/ItemList")
	examples["viewport"] = ui.get_node("Control/vitya/container/column/ScrollContainer/container/ViewportContainer")
	examples["colorpicker"] = ui.get_node("Control/vitya/container/column/ScrollContainer/container/colorpicker")
	examples["lineedit"] = ui.get_node("Control/vitya/container/column/ScrollContainer/container/LineEdit")
	for example_index in examples:
		var example = examples[example_index]
		example.visible = false
	
func _ready():
	var apimanager = get_node_or_null("/root/BlueberryWolfiAPIs")
	if not apimanager: return # no dependency
	while len(apimanager.modules) < len(apimanager.MODULES_LIST):
		yield(get_tree(), "physics_frame") # waiting apis to load
		
	player_api = apimanager.modules["PlayerAPI"]
	keybinds_api = apimanager.modules["KeybindsAPI"]
	
	load_ui()
	set_keybind(KEY_INSERT) # fallback key if failure
	
	
	
	# p.s: in future refactors, functionality should be divided to separate parts.
	#(not right now i'm just lazy)
	functionality = functionality.instance()
	functionality.playerapi = player_api
	functionality.keybindsapi = keybinds_api
	functionality.vityaself = self
	add_child(functionality)
	functionality.hookers_init()
	for column_name in functionality.hookers:
		var column = create_column(column_name)
		for function in functionality.hookers[column_name]:
			var type = array_get(function, 0)
			var title = array_get(function, 1)
			var callable = array_get(function, 2)
			var default = array_get(function, 3)
			var limit = array_get(function, 4)
			if type == "button":
				hook_button(column, title, functionality, callable)
			if type == "check":
				hook_check(column, title, functionality, callable, default)
			if type == "title":
				create_title(column, title)
			if type == "slider":
				hook_slider(column, title, functionality, callable, default) 
			if type == "itemlist":
				hook_itemlist(column, functionality, title, callable, default) # in this case title is actually list array
			if type == "viewport":
				hook_viewport(column, functionality, callable)
			if type == "color":
				hook_color(column, title, functionality, callable, default)
			if type == "line":
				hook_line(column, title, functionality, callable, default, limit)
	main_window.get_node("titlebar").connect("button_down", self, "set", ["moving_window", true])
	main_window.get_node("titlebar").connect("button_up", self, "set", ["moving_window", false])
	notificate("Vityamod v1.0.0 loaded.")
	
func _process(delta):
	
	var current_pos = get_viewport().get_mouse_position()
	if moving_window:
		var relative = current_pos-mouse_position
		main_window.rect_position = Vector2(main_window.rect_position+relative)
		
	mouse_position = current_pos
	
	if statusbar.visible:
		var money = str(PlayerData.money)+"$"
		statusbar.text = "Vityamod v1.0.0 | " + Time.get_date_string_from_system().replace("-", ".") + " " + Time.get_time_string_from_system() + " | " + money
