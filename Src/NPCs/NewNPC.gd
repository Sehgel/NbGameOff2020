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
var nextDialogue: String
var dialogTyping: bool

# gonna comment this .... later 

func _ready() -> void:
	set_process(false)
	Events.connect("dialog_typing_changed", self, "onDialogTypingChanged")
	Events.connect("no_branch_option_pressed", self, "onNoBranchButtonPressed")
	Events.connect("dialog_button_pressed", self, "onDialogButtonPressed")

	Events.connect("hide_dialog", self, "onDialogHidden")
	connect("body_entered", self, "onBodyEntered")
	connect("body_exited", self, "onBodyExited")
	loadDialogue()
	currentBranch = loadedDialogue["%s0" % interactedCounter]


func _process(delta: float) -> void:
	if not player:
		return
	if Input.is_action_just_pressed("interact") and player.direction.x == 0:
		sayBranch(currentBranch)
		Events.emit_signal("interacted_with_npc", self)
		Events.emit_signal("block_player_movement")
		set_process(false)


func onNoBranchButtonPressed() -> void:
	if not player:
		return
	if currentBranch.has("exitDialogue") and currentBranch["exitDialogue"]:
		exitDialogue()
		if currentBranch.has("nextDialogue") and loadedDialogue.has(currentBranch["nextDialogue"]):
			currentBranch = loadedDialogue.get(currentBranch["nextDialogue"])
		return
	if currentBranch.has("nextDialogue"):
		currentBranch = loadedDialogue.get(currentBranch["nextDialogue"])
		sayBranch(currentBranch)
		return

	exitDialogue()


func onDialogButtonPressed(buttonType: int) -> void:
	if not player:
		return
	var exitDialogueKey = "exitDialogue" + str(buttonType)
	if currentBranch.has(exitDialogueKey) and currentBranch[exitDialogueKey]:
		exitDialogue()
		if loadedDialogue.has(currentBranch["branchID%s" % buttonType]):
			currentBranch = get("option%sBranch" % buttonType)
		return
	currentBranch = get("option%sBranch" % buttonType)
	sayBranch(currentBranch)


func onBodyEntered(body: Node) -> void:
	if body.is_in_group("Player"):
		set_process(true)
		player = body


func onBodyExited(body: Node) -> void:
	if body.is_in_group("Player"):
		set_process(false)
		player = null


func loadDialogue() -> void:
	var file = File.new()
	file.open(dialoguePath, File.READ)
	var dialogue: Dictionary = parse_json(file.get_as_text())
	loadedDialogue = dialogue


func sayBranch(branch: Dictionary) -> void:
	Events.emit_signal("interacted_with_npc", self)
	Events.emit_signal("hud_dialog_show", npcName, npcColor, branch["text"])
	
	if branch.has("branchID0") and branch.has("branchID1"):
		Events.emit_signal("update_no_branch_button_state", false)
		Events.emit_signal("update_branch_button_state", true)
		updateBranchButtons()
		if loadedDialogue.has(branch["branchID0"]):
			option0Branch = loadedDialogue.get(branch["branchID0"])
		if loadedDialogue.has(branch["branchID1"]):
			option1Branch = loadedDialogue.get(branch["branchID1"])
		return

	Events.emit_signal("update_no_branch_button_state", true)
	Events.emit_signal("update_branch_button_state", false)
	var choice = branch["choice"] if branch.has("choice") else "Ok"
	Events.emit_signal("update_dialog_option", Types.DialogButtons.NoBranch, choice)


func updateBranchButtons() -> void:
	if currentBranch.has("branchChoice0"):
		Events.emit_signal("update_dialog_option", Types.DialogButtons.Option0, currentBranch["branchChoice0"])
	if currentBranch.has("branchChoice1"):
		Events.emit_signal("update_dialog_option", Types.DialogButtons.Option1, currentBranch["branchChoice1"])

	
# this function is meant to be overriden
func checkForQuests() -> void:
	pass


func setInteractedCounter(value: int) -> void:
	if interactedCounter != value:
		interactedCounter = value
		currentBranch = loadedDialogue["%s0" % interactedCounter]
		set_process(true)


func exitDialogue() -> void:
	checkForQuests()
	Events.emit_signal("hide_dialog")

	
func onDialogHidden() -> void:
	if player:
		set_process(true)


func onDialogTypingChanged(value: bool) -> void:
	dialogTyping = value
