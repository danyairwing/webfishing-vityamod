extends Node

signal new_session
signal entity_added
signal entity_removed
signal dialogue
var runtime = 0
var vitya
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

func vectodict(vector):
	return [vector.x,vector.y,vector.z]
	
func dictovec(dict):
	return Vector3(dict[0],dict[1],dict[2])
	
func colortodic(color): # color to DIH :withered_rose:
	return [color.r, color.g, color.b] 
	
func dictocolor(dic):
	return Color(dic[0], dic[1], dic[2])
	
func reset_camera():
	var lp = lp()
	if lp:
		lp.cam_orbit_node = null

func merge_config(dict):
	vitya.config.merge(dict, false)
		
func join(id):
	if id == -1: return
	get_tree().change_scene("res://Scenes/Menus/Main Menu/main_menu.tscn")
	Network._connect_to_lobby(id)

func rejoin():
	join(Network.STEAM_LOBBY_ID)

func lp(): # LP stands for Local Player
	var player = vitya.player_api.local_player
	if not is_instance_valid(player): return null
	return player


func get_player_from_name(playername):
	for player in vitya.player_api.players:
		if is_instance_valid(player):
			var name = vitya.player_api.get_player_name(player)
			if name == playername: return player

func on_dialogue(dialogue): emit_signal("dialogue", dialogue)

func on_entity_added(entity): emit_signal("entity_added", entity)
func on_entity_removing(entity): emit_signal("entity_removed", entity)
		
func get_all_entities():
	var main = get_main()
	if main == null: return []
	return main.get_node("entities").get_children()
		
func get_main():
	return get_tree().root.get_node("/root/world/Viewport/main")
		
func on_new_session(): 
	emit_signal("new_session")
	
	var lp = lp()
	world = lp.world
	var dialogue = lp.hud.get_node("main/dialogue")
	dialogue.connect("visibility_changed", self, "on_dialogue", [dialogue])
	
	get_main().get_node("entities").connect("child_entered_tree", self, "on_entity_added")
	get_main().get_node("entities").connect("child_exiting_tree", self, "on_entity_removing")
		
func _ready():
	vitya.player_api.connect("_ingame", self, "on_new_session")
func _process(delta): runtime += delta
