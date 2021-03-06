
tool
extends Control

signal enter_menu_mode

var base_branch_scn: PackedScene = preload("res://addons/DialogueEditor/BaseBranch.tscn")
var quest_scn: PackedScene = preload("res://addons/DialogueEditor/QuestNode.tscn")
var love_node_scn: PackedScene = preload("res://addons/DialogueEditor/LoveNode.tscn")
var graph_edit: GraphEdit = GraphEdit.new()
var node_index: int
var files: Array = []
var csv_files: Array = []
var node_offset: Vector2 = Vector2(160, 0)
var selected_node: Node
var csv_save: PoolStringArray
var prefix: String = "BOSS"


# will be converted to the json file
var dict = {
	
}

func _ready() -> void:
	$UpdateFileList.connect("pressed", self, "index_files")
	index_files()
	open_file($Bar/hbox/FileSelect.get_item_text(0))


func index_files() -> void:
	$Bar/hbox/FileSelect.clear()
	var dir = Directory.new()
	if dir.open("res://Src/Dialogues") == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				files.push_front(file_name)
				$Bar/hbox/FileSelect.add_item(file_name, 0)
			file_name = dir.get_next()			
			
			
	$Bar/hbox/TranslationFiles.clear()
	if dir.change_dir("res://Translations/NPC") == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".csv"):
				csv_files.push_front(file_name)
				$Bar/hbox/TranslationFiles.add_item(file_name, 0)
			file_name = dir.get_next()


func save_dict_to_editing_file() -> void:
	var json_string: String = JSON.print(dict, "\t")
	var file := File.new()
	var file_path: String = "res://Src/Dialogues/%s" % $Bar/hbox/FileSelect.get_item_text($Bar/hbox/FileSelect.selected)
	file.open(file_path, File.WRITE)
	file.store_string(json_string)
	file.close()
	
	
func save_connection_list_to_dict() -> void:
	dict = {}
	dict["nodes"] = {}
	
	for child in $GraphEdit.get_children():
		if child is GraphNode:
			if child is QuestNode:
				child.title = "Quest" + str(child.get_quest()) if child.get_quest() != 9999 else child.title
				child.name = child.title
			if child is LoveNode:
				child.title = "Love" + str(child.get_id())
				child.name = child.title
				
			if child is BaseBranch:
				child.title = child.get_node("BranchID").text if child.get_node("BranchID").text != "" else child.title
			
			dict["nodes"][child.title] = [child.offset.x, child.offset.y]
			if child is LoveNode:
				dict["nodes"][child.title].append(child.get_love_points())

			if not dict.has(child.title):
				dict[child.title] = {}
			if child is BaseBranch:
				# branchText
				for i in 3:
					dict[child.title]["branchText%s" % i] = child.get_node("LineEdit%s" % i).text
				
	var connection_list = $GraphEdit.get_connection_list()
	
	for i in connection_list.size():
		var from_branch_choice: int
		var to_branch: String
		var from_node = $GraphEdit.get_node(connection_list[i].from)
		var to_node = $GraphEdit.get_node(connection_list[i].to)
		
		if connection_list[i].from_port == 0:
			from_branch_choice = connection_list[i].to_port - 1
			from_node = $GraphEdit.get_node(connection_list[i].to)
			to_node = $GraphEdit.get_node(connection_list[i].from)
			to_branch = to_node.title
		else:
			from_branch_choice = connection_list[i].from_port - 1
			to_branch = $GraphEdit.get_node(connection_list[i].to).title
		
		if not dict.has(from_node.title):
			dict[from_node.title] = {}
		dict[from_node.title]["branchID%s" % from_branch_choice] = to_branch
		
		if to_node is QuestNode:
			dict[from_node.title]["quest"] = to_node.title.replace("Quest", "")
			dict[from_node.title]["exitDialogue"] = true
			dict[from_node.title].erase("branchID%s" % from_branch_choice)
		if to_node is LoveNode:
			dict[from_node.title]["love_points"] = to_node.get_love_points()
		
			
	for i in $GraphEdit.get_children().size():
		var child = $GraphEdit.get_child(i)
		if not child is GraphNode:
			continue
		if dict.has(child.title):
			var branch_amount: int
			for j in dict[child.title].keys().size():
				if dict[child.title].keys()[j].begins_with("branchID"):
					branch_amount += 1
			if branch_amount == 1:
				var to_branch
				for j in 3:
					var branch_value = "branchID%s" % j
					if dict[child.title].has(branch_value) and dict[child.title][branch_value] != "":
						to_branch = dict[child.title][branch_value]
					dict[child.title].erase(branch_value)
				if not dict[child.title].has("love_points"):
					dict[child.title]["nextDialogue"] = to_branch
				else:
					dict[child.title]["connected_love_node"] = to_branch
					if dict[to_branch].has("nextDialogue"):
						dict[child.title]["afterLoveDialogue"] = dict[to_branch]["nextDialogue"]
			elif branch_amount == 0 and child is BaseBranch:
				dict[child.title]["exitDialogue"] = true
	
	

func _on_graph_connection_request(from, from_slot, to, to_slot):
	$GraphEdit.connect_node(from, from_slot, to, to_slot)


func _on_graph_disconnection_request(from, from_slot, to, to_slot):
	$GraphEdit.disconnect_node(from, from_slot, to, to_slot)


func _on_add_branch_pressed() -> void:
	var branch: GraphNode = base_branch_scn.instance()
	$GraphEdit.add_child(branch)
	branch.offset = $GraphEdit.scroll_offset + Vector2(600, 260)
	node_index += 1
	branch.name = "Branch " + str(node_index)
	branch.title = str(node_index)
	

func _on_save_pressed():
	save_connection_list_to_dict()
	save_dict_to_editing_file()
	save_csv()

	
func open_file(file_name: String) -> void:
	clear_graph()
	var file_path: String = "res://Src/Dialogues/%s" % file_name
	var file := File.new()
	file.open(file_path, File.READ)
	var file_dict: Dictionary = parse_json(file.get_as_text())
	file.close()
	parse_connection_dict(file_dict)
	
	
func parse_connection_dict(dict: Dictionary) -> void:
	clear_graph()
	# adding nodes to graph
	var node_dict
	if dict.has("nodes"):
		node_dict = dict["nodes"]
	else:
		printerr("Cannot read file!")
	
	for i in node_dict.keys().size():
		if node_dict.keys()[i].begins_with("Quest"):
			var quest = quest_scn.instance()
			$GraphEdit.add_child(quest)
			var key_string = node_dict.keys()[i]
			quest.name = key_string
			quest.title = quest.name
			quest.get_node("LineEdit").text = quest.name.replace("Quest", "")
			quest.offset = Vector2(node_dict.values()[i][0], node_dict.values()[i][1])
		elif node_dict.keys()[i].begins_with("Love"):
			var love_node = love_node_scn.instance()
			$GraphEdit.add_child(love_node)
			var key_string = node_dict.keys()[i]
			var value = node_dict.values()[i]
			love_node.title = key_string
			love_node.name = love_node.title
			love_node.get_node("ID").text = love_node.name.replace("Love", "")
			love_node.get_node("LineEdit").text = str(value[2])
			love_node.offset = Vector2(node_dict.values()[i][0], node_dict.values()[i][1])
		else:
			var branch = base_branch_scn.instance()
			$GraphEdit.add_child(branch)
			branch.title = node_dict.keys()[i]
			branch.get_node("BranchID").text = branch.title
			branch.offset = Vector2(node_dict.values()[i][0], node_dict.values()[i][1])

		
	# connecting nodes
	var keys = dict.keys()
	for i in keys.size():
		var key = keys[i]
		if key == "nodes":
			continue
		var from = get_node_from_title(key)
		var branches = dict[key]
		for j in branches.keys().size():
			var found = branches.keys()[j]
			if found == "nextDialogue":
				var from_port = 1
				var to_port = 0
				var to = get_node_from_title(branches.values()[j])
				$GraphEdit.connect_node(from.name, from_port, to.name, to_port)
			elif found.begins_with("branchID"):
				var from_port = int(found.replace("branchID", "")) + 1
				var to_port = 0
				var to = get_node_from_title(branches.values()[j])
				$GraphEdit.connect_node(from.name, from_port, to.name, to_port)
			elif found.begins_with("quest"):
				var to = get_node_from_title("Quest" + str(branches.values()[j]))
				$GraphEdit.connect_node(from.name, 1, to.name, 0)
			elif found.begins_with("branchText"):
				var index := int(found.replace("branchText", ""))
				from.get_node("LineEdit%s" % index).text = branches.values()[j]
			elif found.begins_with("connected_love_node"):
				var from_port = 1
				var to_port = 0
				var to = get_node_from_title(branches.values()[j])
				$GraphEdit.connect_node(from.name, from_port, to.name, to_port)
	
	update_translations($Bar/hbox/TranslationFiles.selected)		

func clear_graph():
	$GraphEdit.clear_connections()
	node_index = 0
	for child in $GraphEdit.get_children():
		if child is GraphNode:
			$GraphEdit.remove_child(child)
			child.queue_free()


func get_node_from_title(title: String) -> GraphNode:
	for child in $GraphEdit.get_children():
		if child is GraphNode and child.title == title:
			return child
	return null


func _on_add_quest():
	var quest_node = quest_scn.instance()
	$GraphEdit.add_child(quest_node)
	quest_node.offset = $GraphEdit.scroll_offset + Vector2(600, 260)
	node_index += 1


func _on_node_selected(node):
	if node is GraphNode:
		selected_node = node


func _on_file_selected(index: int) -> void:
	var file = $Bar/hbox/FileSelect.get_item_text(index)
	
	match file:
		"BossDialogueEditor.json":
			prefix = "BOSS"
		"SecretaryDialogueEditor.json":
			prefix = "SECRETARY"
		"SecretaryFinalDialogueEditor.json":
			prefix = "NATASJA"
	
	open_file(file)
	



func update_translations(index: int) -> void:
	var file := File.new()
	var file_path = "res://Translations/NPC/%s" % $Bar/hbox/TranslationFiles.get_item_text(index)
	if file.open(file_path, File.READ) == OK:
		var csv_line: Array = file.get_csv_line()
		while csv_line[0] != "END":
			var key_text = csv_line[0]
			if key_text.begins_with(prefix + "_KEY_"):
				var node = get_node_from_title(key_text.replace(prefix + "_KEY_", ""))
				if node != null:
					node.set_text(csv_line[1]) #Call setter function
			elif key_text.begins_with(prefix + "_CHOICE_"):
				var thing = key_text.replace(prefix + "_CHOICE_", "").split("_")
				var node = get_node_from_title(thing[0])
				if node != null:
					node.get_node("LineEdit%s" % thing[1]).text = csv_line[1]
			csv_line = file.get_csv_line()
	else:
		printerr("Couldn't open file at %s" % file_path)
		

func save_csv() -> void:
	var file := File.new()
	var file_path = "res://Translations/NPC/%s" % $Bar/hbox/TranslationFiles.get_item_text($Bar/hbox/TranslationFiles.selected)
	if file.open(file_path, File.WRITE) == OK:
		file.store_line("keys,en,ru,de")
		for child in $GraphEdit.get_children():
			if child is BaseBranch:
				var string: String = ""
				string += prefix + "_KEY_%s," % child.get_node("BranchID").text
				string += "\"%s\",," % child.get_node("Text").text
				file.store_line(string)
				for i in 3:
					if child.get_node("LineEdit%s" % i).text != "":
						var choice_string: String = ""
						choice_string += prefix + "_CHOICE_%s_%s," % [child.get_node("BranchID").text, i]
						choice_string += "\"%s\",," % child.get_node('LineEdit%s' % i).text
						file.store_line(choice_string)
		file.store_line("END,,,")
		file.close()


func _on_add_love():
	var love_node = love_node_scn.instance()
	$GraphEdit.add_child(love_node)
	love_node.offset = $GraphEdit.scroll_offset + Vector2(600, 260)
	node_index += 1
