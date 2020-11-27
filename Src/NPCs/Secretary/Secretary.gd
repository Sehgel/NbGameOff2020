extends NPC

func _ready() -> void: 
	interacted_counter = Global.gameState["interactionCounters"]["secretary"]
	Events.connect("tutorial_finished", self, "onTutorialFinished")

	
func onTutorialFinished() -> void:
	Global.gameState["interactionCounters"]["secretary"] += 1
	interacted_counter += 1