extends Area2D
class_name Pickupable

export var pickupName: String
export var showGameHints: bool = true
var isPickedUp: bool = false
var mainNode = self # this is needed for the pressure button, don't remove this
var applyGravity: bool = false
var grav: int = 8000

onready var sprite: Sprite = $Sprite # also for pressure button


func _ready() -> void:
	# for pressure
	set_collision_layer_bit(9, true)
	$GroundDetection.connect("apply_gravity", self, "setApplyGravity", ["dummy", true])
	$GroundDetection.connect("body_entered", self, "setApplyGravity", [false])
	
func _physics_process(delta: float) -> void:
	var velocity = Vector2(0,0)
	if applyGravity:
		velocity.y += grav * delta
		
	global_position += velocity * delta
	
func pickup() -> void:
	isPickedUp = true
	if showGameHints:
		Events.emit_signal("hud_game_hint", "Picked up " + str(pickupName))
	
func drop() -> void:
	isPickedUp = false
	if showGameHints:
		Events.emit_signal("hud_game_hint", "Dropped " + str(pickupName))

func getProgessState() -> bool:
	return isPickedUp

func setApplyGravity(_dummyargument, to: bool):
	applyGravity = to
