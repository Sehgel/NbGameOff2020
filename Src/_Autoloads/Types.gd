extends Node

enum Direction { Top, Right, Down, Left }
enum GameStates {Menu, Game, Settings} 

# HUD
enum HudNotificationType {BuyZone, SaveZone, OpenDoor, Interact}

# Player
enum LightLevels {Dark = 0, BarelyVisible = 1, FullLight = 2}
enum AudioLevels {LoudNoise = 0, SmallNoise = 1, Silent = 2}
enum PlayerStates {Normal, WallDodge, Duck}
enum DetectionLevels{Possible, Sure}
enum UpgradeTypes {Taser_Extended_Battery, Taser_Voltage, False_Alarm, Fitness_Level2, Sneak, DarkNet, Lockpick_Level2, Distraction}

# Minigames
enum Minigames{Test, Keypad, WireCut, Lockpick, Photo}
enum MinigameResults{Failed, Succeeded, Doing}

# Objects
enum GuardStates {Wander, Suspect, PlayerDetected, Stunned}
enum CameraStates {Normal, Suspect, PlayerDetected, Rotating, Frozen}
enum WireColors {Red, Purple,Green, Blue}
enum NotifierTypes{Exclamation, Question}
enum NoteType {SecretService, Local}

# Levels
enum LevelTypes {Western, Eastern}

# Dialog
enum DialogButtons {Option0 = 0, Option1 = 1, NoBranch = 2}