class_name MinigameDoor
extends WireCutSpawner

export var connected_door_path: NodePath
var can_teleport: bool = false

onready var connected_door: Door = get_node_or_null(connected_door_path)
onready var player: Player = Global.player

func _ready() -> void:
	# connections
	if not connected_door:
		print("No connect door for " + name)
	

func _process(_delta: float) -> void:
	# teleporting
	if can_teleport:
		if player_entered:
			if Input.is_action_just_pressed("interact"):
				teleport()
	
	
func teleport() -> void:
	# teleports to connected door
	if connected_door:
		player.global_position = connected_door.get_node("PlayerTeleportPosition").global_position
	else:
		print("Trying to teleport but no connected door for " + name)
	
	
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerArea"):
		player_entered = true
		set_process(true)
		
		
func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("PlayerArea"):
		player_entered = false
		set_process(false)


func _on_minigame_result_changed(result: int) -> void:
	if result == Types.MinigameResults.Succeeded:
		can_teleport = true
		can_make_minigame = false
