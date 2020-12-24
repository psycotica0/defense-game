extends Spatial

const SCAN_RPM = 60.0 / 5.0

onready var barrelCast = $"Gun Holder/BarrelCast"
onready var aboveCast = $"Gun Holder/AboveCast"
onready var topCast = $"Gun Holder/TopCast"
onready var belowCast = $"Gun Holder/BelowCast"

var scanOrder = []

onready var gunHolder = $"Gun Holder"

var source
var circuit

var currentTarget

func _ready():
	scanOrder = [barrelCast, aboveCast, belowCast, topCast]
	for ray in scanOrder:
		ray.enabled = true

func changeCircuit(newCircuit):
	circuit = newCircuit

func _physics_process(delta):
	var previousTarget = currentTarget
	currentTarget = null
	# Check Rays
	# My logic here is that I'll set current target to the first thing my
	# rays see, in the priority order I've listed them, unless any of them see
	# the target I had last update. That takes ultimate priority
	for ray in scanOrder:
		var obj = ray.get_collider()
		if obj:
			if obj == previousTarget:
				currentTarget = obj
				break
			elif not currentTarget and obj.has_method("getAimTarget"):
				currentTarget = obj
	
	if currentTarget:
		# Do Shootsin
		gunHolder.look_at(currentTarget.getAimTarget(), -source.normal)
	else:
		# Continue to scan
		gunHolder.rotate_y((SCAN_RPM / 60.0) * TAU * delta)
		gunHolder.rotation.x = 0
