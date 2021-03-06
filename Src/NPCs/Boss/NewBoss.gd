extends NewNPC


func _ready() -> void:
	if Global.gameState.interactionCounters.boss == 0:
		Global.gameState.level.missionIsTutorial = true

	setInteractedCounter(Global.gameState["interactionCounters"]["boss"])
	Events.connect("tutorial_finished", self, "_on_tutorial_finished")

# gets called when player goes through one iteration of the dialog
func checkForQuests() -> void:
	.checkForQuests() # calls super class function
	if currentBranch.has("quest"):
		Global.game_manager.quest_index = int(currentBranch["quest"])
		# Events.emit_signal("hud_game_hint", Global.levelTitle[Global.game_manager.quest_index])
		Events.emit_signal("level_hint", Global.levelTitle[Global.game_manager.quest_index])

		# game state stuff for saving
		if Global.game_manager.quest_index != 0:
			Global.gameState["level"]["hasActiveMission"] = true
			Global.gameState["level"]["missionIsTutorial"] = false
			Global.gameState["level"]["lastActiveMission"] = Global.game_manager.quest_index
			
			
func _on_tutorial_finished() -> void:
	Global.gameState["interactionCounters"]["boss"] = 1
	setInteractedCounter(1)
