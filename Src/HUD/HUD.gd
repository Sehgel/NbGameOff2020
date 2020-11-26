extends CanvasLayer

enum HoverType {Light, Audio, Web}

var count = 0
var detected_value: int

var nextText: String
var nextName: String
var nextNameColor: String
var currentText: String
var hideWithE: bool = false
var currentSelectedUpgrade: int = 0
var dialogIsTyping: bool = false

onready var dialogTypeTimer: Timer = $Dialog/DialogueTypeTimer

func _ready():
	$AlarmIndicator/Label.set_text(str(detected_value))
	dialogTypeTimer.connect("timeout", self, "onDialogTypeTimerTimeout")
	Events.connect("visible_level_changed", self, "updateLightLevel")
	Events.connect("audio_level_changed", self, "updateAudioLevel")
	
	Events.connect("hud_note_show", self, "showNote")
	Events.connect("hud_dialog_show", self, "showDialog")
	Events.connect("hud_upgrade_window_show", self, "showUpgrade")
	Events.connect("hud_save_window_show", self, "showSave")
	Events.connect("hide_save", self, "onHideSave")

	Events.connect("sure_detection_num_changed", self, "alarmIndication")
	Events.connect("taser_fired", self, "taserUpdate")
	Events.connect("allowed_detections_updated", self, "allowedDetectionsUpdate")
	Events.connect("hide_dialog", self, "hideDialog")
	
	Events.connect("hud_update_money", self, "moneyUpdate")
	Events.connect("hud_mission_briefing", self, "showMissionBriefing")

	Events.connect("hud_game_over", self, "showGameOverNotification")
	Events.connect("hud_game_hint", self, "showGameHintNotification")

	Events.connect("hud_photo_flash", self, "photoFlash")

	for node in $Upgrades/Grid.get_children():
		node.connect("Upgrade_Button_Pressed", self, "upgradeSelect")

	var cat = Debug.addCategory("HUD")
	Debug.addOption(cat, "ShaderToggle", funcref(self, "debugShaderToggle"), null)
	detected_value = Global.game_manager.getCurrentLevel().allowed_detections


func _process(delta: float) -> void:
	if nextText != "":
		if Input.is_action_just_pressed("interact"):
			Events.emit_signal("hud_dialog_show", nextName, nextNameColor, nextText)


func photoFlash():
	$PhotoFlash/AnimationPlayer.play("detection")

func showGameHintNotification(text):
	$GameHintNotification.set_text(text)
	$GameHintNotification.show()
	$GameHintNotification/GameHintAnimationPlayer.play("pop")

func _on_GameHintAnimationPlayer_animation_finished(anim_name):
	$GameHintNotification.hide()


func showGameOverNotification():
	$GameOverNotification.show()
	$GameOverNotification/GameOverNotifcationAnimationPlayer.play("pop")

func _on_GameOverNotifcationAnimationPlayer_animation_finished(anim_name):
	$GameOverNotification.hide()
	Events.emit_signal("hud_game_over_exited")


func showMissionBriefing(level):
	$MissionBriefing/StartMissionButton.grab_focus()
	$MissionBriefing.setLevel(level)
	$MissionBriefing.show()

func debugShaderToggle(_d):
	if $Shader.visible:
		$Shader.hide()
	else:
		$Shader.show()


func showSave():
	Events.emit_signal("block_player_movement")
	var saves = Global.getSaveGameState()
	
	var i = 1
	for element in saves:
		var button = get_node("SaveGame/Menu/ButtonSave" + str(i))
		if element == true: # File Exists
			button.updateLabel("Slot " + str(i) + " (Overwrite)")
		else:
			button.updateLabel("Slot " + str(i) + " (New)")
		i += 1
	$SaveGame.show()
	$SaveGame/Menu/ButtonReturn.grab_focus()


func save(slot):
	Global.saveGame(slot)


func moneyUpdate(total, change):
	$MoneyIndicator/Label.set_text(str(total))
	
	if change == 0:
		pass
	elif change < 0:
		$MoneyIndicator/AnimationPlayer.play("moneyDown")
	else:
		$MoneyIndicator/AnimationPlayer.play("moneyUp")

	if $Upgrades.visible:
		# Update button if money is enough
		upgradeSelect(currentSelectedUpgrade)

func taserUpdate(value):
	$ChargeIndicator.frame = 3 - value
	$ChargeIndicator/Label.set_text(str(value))


func alarmIndication(value):
	if detected_value >= 0:
		detected_value -= 1
		$DetectFlash/AnimationPlayer.play("detection")
		$AlarmIndicator/AlarmAnimation.play("downgrade")
		$AlarmIndicator/Label.set_text(str(detected_value))


func allowedDetectionsUpdate(value) -> void:
	detected_value = value if value >= 0 else 0
	$AlarmIndicator/Label.set_text(str(detected_value))
	
	
func showNote(type, text):
	if type == Types.NoteType.Local:
		$Note.texture = preload("res://Assets/HUD/NoteLocal.png")
	else:
		$Note.texture = preload("res://Assets/HUD/Note.png")

	$Note/Text.bbcode_text = str(text)
	Events.emit_signal("play_sound", "note_open")
	$Note.show()




func updateUpgrades():
	# Clear old results
#	for node in $Upgrades/Grid.get_children():
#		node.disabled = false
#	for upgradeId in Global.gameState.playerUpgrades:
#		get_node("Upgrades/Grid/UpgradeButton" + str(upgradeId)).disabled = true
	pass


func _on_UpgradeButton_button_up():
	var upgrade = Global.upgrades[currentSelectedUpgrade]
	if Global.gameState.money >= upgrade.cost:
		Global.addUpgrade(currentSelectedUpgrade)
		Global.addMoney(-upgrade.cost)
		upgradeSelect(currentSelectedUpgrade)
	

func upgradeSelect(id):
	currentSelectedUpgrade = id
	var upgrade = Global.upgrades[id]
	$Upgrades/InfoBox/Titel.set_text(upgrade.name + " $" + str(upgrade.cost))
	$Upgrades/InfoBox/Description.bbcode_text = upgrade.desc
	
	if -1 == Global.gameState.playerUpgrades.find(id):
		if Global.gameState.money >= upgrade.cost:
			$Upgrades/InfoBox/UpgradeButton.updateLabel("Buy Upgrade")
			$Upgrades/InfoBox/UpgradeButton.disabled = false
		else:
			$Upgrades/InfoBox/UpgradeButton.updateLabel("Not Enough Cash")
			$Upgrades/InfoBox/UpgradeButton.disabled = true
	else:
		$Upgrades/InfoBox/UpgradeButton.updateLabel("Already Owned")
		$Upgrades/InfoBox/UpgradeButton.disabled = true
		Events.emit_signal("update_upgrades")


func showUpgrade():
	# Set focus so we can use gamepad with ui
	$Upgrades/Grid/UpgradeButton0.grab_focus()
	upgradeSelect(0)
	
	updateUpgrades()
	$Upgrades.show()


func showDialog(pname: String, nameColor: String, text: String):
	 # for multipage dialogue, checks if new line and stores the text after the new line in nextText and other info in variables
	if "\n" in text:
		nextText = text.substr(text.find("\n") + 1)
		text.erase(text.find("\n"), 300) # erases from original text so that it won't have the next page text
		nextName = pname
		nextNameColor = nameColor
	else:
		nextText = ""
		nextName = ""
		nextNameColor = ""

	$Dialog/Text.bbcode_text = "[color="+nameColor+"]"+pname+"[/color]: " + text
	$Dialog.show()
	currentText = text
	typeDialog() # do you want this function or tween. problem with tween is that if the text is short, it will still take 1 second to finish, which is meh. this fixes that
	# dialogTween.interpolate_property($Dialog/Text, "percent_visible", 0.0, 1.0, 1.0, Tween.TRANS_LINEAR)
	# dialogTween.start()


func hideDialog() -> void:
	$Dialog.hide()
	Events.emit_signal("hud_dialog_exited")
	dialogTypeTimer.stop()
	Global.player.set_state(Types.PlayerStates.Normal)


func _physics_process(_delta):
	# Hide Note
	if Input.is_action_just_pressed("close_menu"):
		if $Note.visible:
			$Note.hide()
			Events.emit_signal("hud_note_exited")
		elif $Dialog.visible:
			$Dialog.hide()
			Events.emit_signal("hud_dialog_exited")
		elif $IngameMenu.visible:
			hideMenu()
		elif $Upgrades.visible:
			$Upgrades.hide()
			Events.emit_signal("unblock_player_movement")
		elif $SaveGame.visible:
			onHideSave()
		else:
			showMenu()

			
	# # hide when press E and don't have any more text to show
	# if Input.is_action_just_pressed("interact") and nextText == "" and $Dialog.visible:
	# 	hideDialog()

	setDialogIsTyping($Dialog/Text.visible_characters != $Dialog/Text.text.length() and $Dialog.visible)

	if Input.is_action_just_pressed("interact"):
		if dialogIsTyping:
			$Dialog/Text.visible_characters = $Dialog/Text.text.length()
		else:
			hideDialog()
			Events.emit_signal("unblock_player_movement")


	# hide when press E in note
	if Input.is_action_just_pressed("interact"):
		if $Note.visible:
			$Note.hide()
			Events.emit_signal("hud_note_exited")


func showMenu():
	$IngameMenu.show()
	$IngameMenu/Menu/ButtonReturn.grab_focus()
	get_tree().paused = true
	Events.emit_signal("forcefully_close_minigame")

func hideMenu():
	$IngameMenu.hide()
	get_tree().paused = false

func updateLightLevel(newLightLevel):
	match newLightLevel:
		Types.LightLevels.Dark:
			$LightIndicator.frame = 2
		Types.LightLevels.BarelyVisible:
			$LightIndicator.frame = 1
		Types.LightLevels.FullLight:
			$LightIndicator.frame = 0
		_:
			print("HUD: Illegal light level provided")
	

func updateAudioLevel(newAudioLevel, audio_pos): #TODO: audio_pos needed?
	if newAudioLevel >= 0 and newAudioLevel < Types.AudioLevels.size():
		$AudioIndicator.frame = newAudioLevel
	else:
		print("HUD: Illegal audio level provided")
	
	$AudioIndicator/GoBackToNormal.start()


func _on_GoBackToNormal_timeout() -> void:
	$AudioIndicator.frame = 2


func onHideSave() -> void:
	Events.emit_signal("unblock_player_movement")
	$SaveGame.hide()

	
func hover(type):
	match type:
		HoverType.Web:
			$Hovers/Indicator.position = Vector2(12, 0)
			$Hovers/Label.set_text("Status: Web Monetization Plugin.")
		HoverType.Audio:
			$Hovers/Indicator.position = Vector2(43, 0)
			$Hovers/Label.set_text("This is your noise indicator.")
		_: #Light
			$Hovers/Indicator.position = Vector2(72, 0)
			$Hovers/Label.set_text("This is your visibilty indicator.")
	$Hovers.show()


func onDialogTypeTimerTimeout() -> void:
	if $Dialog/Text.text.length() != $Dialog/Text.visible_characters:
		$Dialog/Text.visible_characters += 1
		Events.emit_signal("play_sound", "type")
	else:
		dialogTypeTimer.stop()


func typeDialog() -> void:
	$Dialog/Text.visible_characters = 0
	dialogTypeTimer.start()
	# while $Dialog/Text.visible_characters < $Dialog/Text.text.length():
	# 	$Dialog/Text.visible_characters += 1
	# 	yield(get_tree(), "idle_frame")


func _on_LightHover_mouse_entered():
	hover(HoverType.Light)


func _on_LightHover_mouse_exited():
	$Hovers.hide()


func _on_AudioHover_mouse_entered():
	hover(HoverType.Audio)


func _on_AudioHover_mouse_exited():
	$Hovers.hide()


func _on_WebHover_mouse_entered():
	hover(HoverType.Web)


func _on_WebHover_mouse_exited():
	$Hovers.hide()


func _on_ButtonQuit_button_up():
	Events.emit_signal("play_sound", "menu_click")
	Events.emit_signal("menu_back")


func _on_ButtonSound_button_up():
	Events.emit_signal("play_sound", "menu_click")
	Events.emit_signal("switch_sound", !Global.userConfig.sound)


func _on_ButtonMusic_button_up():
	Events.emit_signal("play_sound", "menu_click")
	Events.emit_signal("switch_music", !Global.userConfig.music)


func _on_ButtonReturn_button_up():
	Events.emit_signal("play_sound", "menu_click")
	$IngameMenu.hide()
	onHideSave()
	get_tree().paused = false


func _on_ButtonSave1_button_up():
	Events.emit_signal("play_sound", "menu_click")
	save(0)


func _on_ButtonSave2_button_up():
	Events.emit_signal("play_sound", "menu_click")
	save(1)


func _on_ButtonSave3_button_up():
	Events.emit_signal("play_sound", "menu_click")
	save(2)


func _on_StartMissionButton_button_up():
	$MissionBriefing.hide()
	Events.emit_signal("play_sound", "menu_click")
	Events.emit_signal("hud_mission_briefing_exited")


func setDialogIsTyping(value: bool) -> void:
	if dialogIsTyping != value:
		dialogIsTyping = value
		Events.emit_signal("dialog_typing_changed", dialogIsTyping)


func _on_MenuButton_button_up():
	if $IngameMenu.visible:
		hideMenu()
	else:
		showMenu()
