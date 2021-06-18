extends Line2D
class_name PathLine

# reworked this to remove all yields and be less magic - knightmare

signal next_point_reached

export var stop_time: float = 1.5
export var stopOnReachedPoint: bool = true
export var distractWaitTime: float = 2

var global_points: Array = []
var next_point: Vector2
var last_point: Vector2
var enabled: bool = true
var is_next_point_reached: bool
var movingToCustomPoint: bool = false
var currentIndex: int
var timer: Timer = Timer.new()
var distractTimer: Timer = Timer.new()

var isDistract: bool = false

onready var target = get_parent()


func _ready() -> void:
	add_child(distractTimer)
	distractTimer.connect("timeout", self, "onDistractTimerTimeout")
	distractTimer.one_shot = true
	distractTimer.wait_time = distractWaitTime

	add_child(timer)
	timer.connect("timeout", self, "onTimerTimeout")
	timer.one_shot = true
	timer.wait_time = stop_time
	hide()

	for i in points.size():
		global_points.append(target.to_global(points[i]))
	
	
	last_point = global_points[0]
	
	moveToNextPoint()	
	if global_points.size() >= 1:
		next_point = global_points[0]


func _process(delta: float) -> void:
	if enabled or movingToCustomPoint:
		if abs(int(next_point.x) - int(target.global_position.x)) <= 10:
			target.direction.x = 0
			if not is_next_point_reached:
				is_next_point_reached = true
				emit_signal("next_point_reached")
				if not movingToCustomPoint:
					moveToNextPoint()
		elif int(next_point.x) > int(target.global_position.x):
			target.direction.x = 1
			is_next_point_reached = false
		elif int(next_point.x) < int(target.global_position.x):
			target.direction.x = -1
			is_next_point_reached = false


func onTimerTimeout() -> void:
	if global_points.size() - 1 >= currentIndex:
		last_point = next_point
		next_point = global_points[currentIndex]


func moveToNextPoint():
	if currentIndex >= global_points.size() - 1:
		currentIndex = 0
		if not isDistract:
			global_points.invert()
		else:
			# stopping because we reached the last point and this is for distraction
			stopAllMovement()
			distractTimer.start(distractWaitTime)
	currentIndex += 1
	if stopOnReachedPoint:
		timer.start()
	else:
		last_point = next_point
		next_point = global_points[currentIndex]


func moveToPoint(newPoint: Vector2) -> void:
	last_point = next_point
	next_point = newPoint
	moveToNextPoint()
	enabled = false
	movingToCustomPoint = true
	timer.stop()


func startNormalMovement() -> void:
	movingToCustomPoint = false
	enabled = true
	timer.start(0.3) # experimental line of code, don't know if this will break anything else

	
func stopAllMovement() -> void:
	enabled = false
	movingToCustomPoint = false
	target.direction = Vector2(0,0)
	timer.stop()

	
func changeDirection() -> void:
	enabled = true
	movingToCustomPoint = false
	global_points.invert()
	timer.start()


func moveToLastPoint() -> void:
	next_point = last_point
	moveToNextPoint()
	enabled = true
	movingToCustomPoint = false
	timer.start()


func onDistractTimerTimeout() -> void:
	if target.has_method("normalMode"):
		target.normalMode()
