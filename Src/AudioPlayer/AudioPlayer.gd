extends Node2D

export (Array, AudioStream) var guardAlarmSounds
export (Array, AudioStream) var guardSuspiciousSounds

onready var randomSound := $RandomSound

func _ready():
	# Event Hooks
	Events.connect_signal("play_sound", self, "_playSound")
	Events.connect_signal("switch_music", self, "_switchMusic")
	
	# Init Start Music
	_switchMusic(Global.userConfig.music) 

###############################################################################
# Callbacks
###############################################################################

# Event Hook: Play or stop music
func _switchMusic(val: bool):
	if val:
		$Music.play()
	else:
		$Music.stop()

# Event Hook: Play a sound
func _playSound(sound: String, _volume : float = 1.0, _pos : Vector2 = Vector2(0, 0)):
	if Global.userConfig.sound:
		match sound:
			"menu_click":
				$MenuClick.play()
			"example":
				$Example2D.volume_db = -20 + 12 * _volume
				$Example2D.position = _pos
				$Example2D.play()
			"jump_down":
				$PlayerSounds/JumpDown.play()
			"alarm":
				playRandomSound(guardAlarmSounds)
			"jump_up":
				$PlayerSounds/JumpUp.play()
			"suspicious":
				playRandomSound(guardSuspiciousSounds)
			"taser_hit":
				$PlayerSounds/TaserHit.play()
			"taser_deploy":
				$PlayerSounds/TaserDeploy.play()
			"minigame_fail":
				$MinigameSounds/MinigameFail.play()
			"camera_alarm":
				$CameraSounds/Alarm.play()
			"camera_beep":
				$CameraSounds/Beep.play()
			_:
				print("error: sound not found - name: " + str(sound))


		

# Music Loop?
func _on_Music_finished():
	pass # Replace with function body.

func playRandomSound(array: Array) -> void:
	randomSound.stream = array[randi() % array.size()]
	randomSound.play()
