extends ThinArea

func _ready():
	if disabled:
		$DSprite.frame = 0
	else:
		$DSprite.frame = 2
	pass


func toggleState():
	print("Try toogle")
	if disabled:
		$AnimationPlayer.play("OpenDoor")
		disabled = false
	else:
		$AnimationPlayer.play_backwards("OpenDoor")
		disabled = true
	Events.emit_signal("play_sound", "door_metal_open", 1.0, Global.calcAudioPosition(global_position))
