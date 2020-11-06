extends Area2D

var player_entered: bool = false


func _process(delta: float) -> void:
	if player_entered:
		if Global.player.state != Types.PlayerStates.WallDodge:
			Events.emit_signal("player_detected", Types.DetectionLevels.Sure)
			set_process(false)
			
			
func _on_Laser_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerArea"):
		player_entered = true
		set_process(true)


func _on_Laser_area_exited(area: Area2D) -> void:
	if area.is_in_group("PlayerArea"):
		player_entered = false
		set_process(true)
