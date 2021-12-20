extends Node

signal destination_reached
export(NodePath) var target
export(String) var property
export(float) var acceleration = 180
export(int, 0, 360) var targetSpeed = 360
export var active = true
# This isn't really exported, but this is the one we're expected to twiddle from the outside
var targetValue = 0

var currentSpeed = 0
var realTarget
var realProperty

func _ready():
	realTarget = get_node(target)
	realProperty = NodePath(property)

func _physics_process(delta):
	if not active:
		return
	
	var currentValue = realTarget.get_indexed(realProperty)
	var difference = targetValue - currentValue
	
	if abs(difference) <= 0.01:
		difference = 0
	
	if difference == 0 and currentSpeed == 0:
		# We did it!
		if active:
			active = false
			emit_signal("destination_reached")
	
	if difference > 0:
		# I rearranged (v = v0 + at) and (d = v0t + 1/2 a t^2) to get "how far will I travel if I stop now"
		# So compute that and if we're in that window, then start stopping
		var stoppingDistance = currentSpeed*currentSpeed / (2 * acceleration)
		if currentValue + stoppingDistance >= targetValue:
			# Be stopping
			currentSpeed = clamp(currentSpeed - acceleration * delta, 0, targetSpeed)
		else:
			# Speed up
			currentSpeed = clamp(currentSpeed + acceleration * delta, -targetSpeed, targetSpeed)
	else:
		# Have to decrease
		var stoppingDistance = currentSpeed*currentSpeed / (2 * acceleration)
		if currentValue - stoppingDistance <= targetValue:
			# Be stopping
			currentSpeed = clamp(currentSpeed + acceleration * delta, -targetSpeed, 0)
		else:
			# Speed up
			currentSpeed = clamp(currentSpeed - acceleration * delta, -targetSpeed, targetSpeed)
	
	if currentSpeed != 0:
		realTarget.set_indexed(realProperty, currentValue + currentSpeed * delta)
