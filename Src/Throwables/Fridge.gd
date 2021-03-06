extends Area2D

export var snackAmount: int = 1
var player: Player


func _ready() -> void:
	set_process_input(false)
	connect("body_entered", self, "onBodyEntered")
	connect("body_exited", self, "onBodyExited")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player != null and player.canInteract:
		var snackThrower = player.weaponHandler.getWeapon(Types.Weapons.SnackThrower)
		snackThrower.currentAmmo += snackAmount
		set_deferred("monitoring", false)
		set_process_input(false)
		if snackAmount == 1:
			Events.emit_signal("hud_game_hint", "Found a snack")
			return
		Events.emit_signal("hud_game_hint", "Found %s snacks" % snackAmount)


func onBodyEntered(body: Node) -> void:
	if body.is_in_group("Player"):
		player = body
		set_process_input(true)


func onBodyExited(body: Node) -> void:
	if body.is_in_group("Player"):
		player = null
		set_process_input(false)
