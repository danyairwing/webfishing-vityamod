extends Node

var shortcuts = {
	"insert":KEY_INSERT,
	"f2":KEY_F2,
	"f3":KEY_F3,
	"tilda":KEY_QUOTELEFT,
	"ctrl":KEY_CONTROL
}

var vitya
var cfg
var functions = {}
func functions_init():
	cfg = vitya.config
	
	vitya.utils.merge_config({
		"transition":false,
		"pricecatch":false,
		"statusbar":true,
		"baitnotif":false,
		"letternotif":false,
		"raincloudnotif":false,
		"rainbow_accent":false,
		"rainbow_bg":false,
		"rainbow_speed":.5,
		"open_shortcut":0
		
	})
	
	functions = {
		"HUD": [
		["check", "no transition", "transition", cfg.transition],
		["check", "show price on catch", "pricecatch", cfg.pricecatch],
		["check", "status bar", "vitya_status", cfg.statusbar],
		["title", "CHAT"],
		#["check", "keep history", "chat_keep_history", cfg.chat_keep_history],
		
		["title", "NOTIFICATIONS"],
		["check", "no bait notification", "baitnotif", cfg.baitnotif],
		["check", "letter notification", "letternotif", cfg.letternotif],
		["check", "raincloud notification", "raincloudnotif", cfg.raincloudnotif],
		["button", "test notifications", "test_notification"],
		["title", "VITYA"],
		
		["check", "rainbow accent", "rainbow_accent", cfg.rainbow_accent],
		["check", "rainbow bg", "rainbow_bg", cfg.rainbow_bg],
		["slider", "rainbow speed", "rainbow_speed", cfg.rainbow_speed],
		
		["color", "accent color", "accent", "default_accent"],
		["color", "bg color", "bg", "default_bg"],
		["title", "shortcut"],
		["itemlist", "shortcutlist", "shortcut_selected", cfg.open_shortcut],
		["button", "contact danyairwing", "open_discord"]
		# TODO: tab container
		]
	}
	vitya.utils.connect("entity_added", self, "_entity_added")
	vitya.utils.connect("new_session", self, "new_session")

	vitya.utils.connect("dialogue", self, "dialogue")
	PlayerData.connect("_letter_update", self, "letter_inbox")


func open_discord():
	OS.shell_open("https://discord.gg/FmZ98UQW2v")

func get_hud():
	return vitya.utils.lp().hud



func chat_updated():
	if not vitya.utils.lp(): return
	var chatbox = get_hud().get_node("main/in_game/gamechat/RichTextLabel")
	if cfg.chat_keep_history:
		pass # TODO: add new data to chat instead of overwrite

func dialogue(dialogue):
	if not cfg.pricecatch: return
	var finder = "You caught a " # bladee reference
	var string = dialogue.bank[0]
	var caught_text = string.find(finder)
	if not caught_text == -1:
		# TODO: lookup the caught fish, check price and add to bank string.
		var item = PlayerData.inventory[len(PlayerData.inventory)-1]
		
		var price = PlayerData._get_item_worth(item["ref"])
		dialogue.get_node("Panel/RichTextLabel").bbcode_text = string.insert(caught_text+len(finder), "[color=#"+Color(0,1,0).to_html()+"]"+ str(price) + "$[/color] ")
		

	# get hud, connect on meta click in chat
func _entity_added(entity):
	if cfg.raincloudnotif:
		if entity.actor_type == "raincloud":
			vitya.notificate("Raincloud spawned!")

func shortcutlist():
	return shortcuts.keys()

func shortcut_selected(index):
	var keycode = shortcuts[vitya.utils.array_get(shortcuts.keys(), index)]
	cfg.open_shortcut = index
	vitya.set_keybind(keycode)

func default_accent(): return vitya.utils.dictocolor(cfg.accent) 
func default_bg(): return vitya.utils.dictocolor(cfg.bg)  

func accent(color):
	vitya.change_accent(color)
	cfg.accent = vitya.utils.colortodic(color) 
	
func bg(color):
	vitya.change_bg(color) 
	cfg.bg = vitya.utils.colortodic(color)
	
func letter_inbox():
	if cfg.letternotif:
		vitya.notificate("A new letter in the mail.")


func transition_off(): 
	cfg.transition = false
	SceneTransition.get_node("AnimationPlayer").playback_speed = 1
func transition_on(): 
	cfg.transition = true
	SceneTransition.get_node("AnimationPlayer").playback_speed = 10000

func vitya_status_on():
	vitya.statusbar.visible = true
	cfg.statusbar = true
func vitya_status_off():
	vitya.statusbar.visible = false
	cfg.statusbar = false
	
func test_notification(): 
	var types = ["error", "warn", "default"]
	vitya.notificate("this is an default notification")
	yield(get_tree().create_timer(1), "timeout")
	vitya.notificate("this is warning", "warn")
	yield(get_tree().create_timer(1), "timeout")
	vitya.notificate("this is an error", "error")
	
	
"""
func bait_on(): cfg.baitnotif = true
func bait_off(): cfg.baitnotif = false

func raincloud_notification_on(): cfg.raincloudnotif = true
func raincloud_notification_off(): cfg.raincloudnotif = false

func letter_on(): cfg.letternotif = true
func letter_off(): cfg.letternotif = false

func pricecatch_off(): cfg.pricecatch = false
func pricecatch_on(): cfg.pricecatch = true

"""

func _process(delta):
	
	if cfg.rainbow_accent:
		var curr_accent = vitya.get_accent_color()
		curr_accent.h += delta*cfg.rainbow_speed
		vitya.change_accent(curr_accent)
	if cfg.rainbow_bg:
		var curr_accent = vitya.get_bg_color()
		curr_accent.h += delta*cfg.rainbow_speed
		vitya.change_bg(curr_accent)
	
	if not vitya.utils.lp(): return 
	if cfg.baitnotif and PlayerData.bait_selected == "": vitya.notificate("No bait! Please restock.")
	
