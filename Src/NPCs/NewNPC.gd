class_name NewNPC
extends Area2D

signal read_all_dialog

export (String, FILE) var dialoguePath: String
export var npcName: String
export var npcColor: String

var loadedDialogue
var option0Branch
var option1Branch
var currentBranch
var player: Player
var interactedCounter = 0


func _ready() -> void:
	set_process(false)
	Events.connect("option0_pressed", self, "onOption0ButtonPressed")
	Events.connect("option1_pressed", self, "onOption1ButtonPressed")
	Events.connect("no_branch_option_pressed", self, "onNoBranchButtonPressed")
	connect("body_entered", self, "onBodyEntered")
	connect("body_exited", self, "onBodyExited")
	loadedDialogue = loadDialogue()
	currentBranch = loadedDialogue["%s0" % interactedCounter]


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact") and player.direction.x == 0:
		sayCurrentBranch()
		Events.emit_signal("interacted_with_npc", self)
		Events.emit_signal("block_player_movement")


func onNoBranchButtonPressed() -> void:
	if currentBranch.has("exitDialogue") and currentBranch["exitDialogue"]:
		emit_signal("read_all_dialog")
		Events.emit_signal("hide_dialog")
		return
	currentBranch = loadedDialogue.get(currentBranch["nextDialogue"])
	sayCurrentBranch()
		

func onOption0ButtonPressed() -> void:
	if currentBranch.has("exitDialogue0") and ["exitDialogue0"]:
		emit_signal("read_all_dialog")
		Events.emit_signal("hide_dialog")
	currentBranch = option0Branch
	sayCurrentBranch()


func onOption1ButtonPressed() -> void:
	if currentBranch.has("exitDialogue1") and currentBranch["exitDialogue1"]:
		emit_signal("read_all_dialog")
		Events.emit_signal("hide_dialog")
		return
	currentBranch = option1Branch
	sayCurrentBranch()
		

func onBodyEntered(body: Node) -> void:
	if body.is_in_group("Player"):
		set_process(true)
		player = body


func onBodyExited(body: Node) -> void:
	if body.is_in_group("Player"):
		set_process(false)


func loadDialogue() -> Dictionary:
	var file = File.new()
	file.open(dialoguePath, File.READ)
	var dialogue: Dictionary = parse_json(file.get_as_text())
	return dialogue


func sayCurrentBranch() -> void:
	Events.emit_signal("interacted_with_npc", self)
	Events.emit_signal("hud_dialog_show", npcName, npcColor, currentBranch["text"])
	
	if currentBranch.has("branchID0"):
		Events.emit_signal("update_no_branch_button_state", false)
		Events.emit_signal("update_branch_button_state", true)
		updateBranchButtons()
		if loadedDialogue.has(currentBranch["branchID0"]):
			option0Branch = loadedDialogue.get(currentBranch["branchID0"])
		if loadedDialogue.has(currentBranch["branchID1"]):
			option1Branch = loadedDialogue.get(currentBranch["branchID1"])
		return

	Events.emit_signal("update_no_branch_button_state", true)
	Events.emit_signal("update_branch_button_state", false)
	Events.emit_signal("update_no_branch_option", currentBranch["choice"])


func updateBranchButtons() -> void:
	if currentBranch.has("branchChoice0"):
		Events.emit_signal("update_option_button0", currentBranch["branchChoice0"])
	if currentBranch.has("branchChoice1"):
		Events.emit_signal("update_option_button1", currentBranch["branchChoice1"])
