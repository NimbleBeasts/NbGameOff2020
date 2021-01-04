extends MinigameSpawner


func create_minigame() -> Minigame:
	var minigame_instance: Minigame = load("res://Src/Minigames/CryptogramMinigame/CryptogramMinigame.tscn").instance()
	
	Global.game_manager.levelNode.get_node(holderNodeInLevel).add_child(minigame_instance)
	minigame_instance.owner_obj = self
	
	# sets position to bottom center of the screen
	var screen_bottom_center = Global.screen_bottom_center
	minigame_instance.global_position = screen_bottom_center
	
	return minigame_instance
