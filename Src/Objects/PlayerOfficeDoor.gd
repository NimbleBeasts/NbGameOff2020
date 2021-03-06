
tool
extends Node2D

var minigame_finished: bool = false
var playerInArea = false
var doorIsOpen = false
var playerNode = null

enum DoorLockType {open, lockedLevel1, lockedLevel2, locked}
enum DoorType {wooden, metal}

export(DoorLockType) var lockLevel = DoorLockType.open
export(DoorType) var doorType = DoorType.wooden
export var door_id = 0

func _ready():
	$LockpickSmallMinigameSpawner.connect("minigame_succeeded", self, "onLockpickMinigameSucceeded")
	$Area2D.connect("body_entered", self,"_on_Area2D_body_entered")
	$Area2D.connect("body_exited", self, "_on_Area2D_body_exited")
	if doorType == DoorType.metal:
		$Sprite.texture = preload("res://Assets/Doors/DoorWallMetal.png")
	else:
		$Sprite.texture = preload("res://Assets/Doors/DoorWall.png")
	set_process(false)
	
	if door_id != 0:
		Events.connect("minigame_door_change_status", self, "_on_minigame_door_change_status")
	

func _process(_delta):
	if playerInArea:
		if Input.is_action_just_pressed("interact"):
			interact()
			
func interact():
	
	if not Global.gameState["playerOfficeDoorIsOpen"]:
		if lockLevel == DoorLockType.lockedLevel1:
			$LockpickSmallMinigameSpawner.run_minigame(door_id, 1, true)
			return
		if lockLevel == DoorLockType.lockedLevel2:
			$LockpickSmallMinigameSpawner.run_minigame(door_id, 2, true)
			return
	else:
		lockLevel = DoorLockType.open
	

	if lockLevel == DoorLockType.open:
		if not doorIsOpen:
			# Open Animation
			if playerNode.position.x < self.global_position.x:
				# Left Side
				$Sprite.scale.x = 1
			else:
				# Right Side
				$Sprite.scale.x = -1
			$AnimationPlayer.play("open_door")
		else:
			# Close Animation
			$AnimationPlayer.play_backwards("open_door")
			

func _on_AnimationPlayer_animation_finished(_anim_name):
	if not doorIsOpen:
		# Door is now open
		doorIsOpen = true
		$StaticBody2D/CollisionShape2D.set_disabled(true)
	else:
		# Door is now closed
		doorIsOpen = false
		$StaticBody2D/CollisionShape2D.set_disabled(false)



func _on_Area2D_body_entered(body):
	if body is Player:
		playerNode = body
		playerInArea = true
		set_process(true)


func _on_Area2D_body_exited(body):
	if body is Player:
		playerNode = null
		playerInArea = false
		set_process(false)

func _on_minigame_door_change_status(id, lock_type, play):
	if id == door_id:
		lockLevel = lock_type
	if play:
		interact()
		

func onLockpickMinigameSucceeded() -> void:
	Global.gameState["playerOfficeDoorIsOpen"] = true
