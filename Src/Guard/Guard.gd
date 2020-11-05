class_name Guard
extends KinematicBody2D

export var speed: int = 50
export var direction_change_time: float = 2
export var starting_direction: Vector2
export var time_to_sure_direction: float = 1.5

var velocity: Vector2
var direction: Vector2
var moving_right: bool = true
var player_detected: bool = false
var stun_area_entered: bool = false


func _ready() -> void:
	# sets the wait_time to the exported variabel
	$DirectionChangeTimer.wait_time = direction_change_time
	$SureDetectionTimer.wait_time = time_to_sure_direction
	$DirectionChangeTimer.start()
	direction = starting_direction 


func _process(delta: float) -> void:
	velocity = direction * speed
	velocity = move_and_slide(velocity)
	

func _on_DirectionChangeTimer_timeout():
	change_direction()
	

func change_direction() -> void:
	# flips moving_right, also flips the direction.x
	moving_right = not moving_right
	direction.x *= -1

# stun function.
func stun() -> void:
	direction = Vector2(0,0)
	$Sprite.modulate = Color.black


func _on_LineOfSight_area_entered(area: Area2D) -> void:
	# detecting player
	if area.is_in_group("PlayerArea"):
		Events.emit_signal("player_detected", Types.DetectionLevels.Possible)
		player_detected = true
		direction = Vector2(0,0)
		if $SureDetectionTimer.is_stopped():
			$SureDetectionTimer.start()


func _on_SureDetectionTimer_timeout() -> void:
	Events.emit_signal("player_detected", Types.DetectionLevels.Sure)


func _on_GuardArea_area_entered(area: Area2D) -> void:
	if area.is_in_group("StunArea"):
		stun_area_entered = true
