extends Spatial

const shieldScene = preload("res://Shield.tscn")

onready var shieldSpawn = $ShieldSpawn

var shield
var direction

var source
var circuit
var demand = 10

# This is a convenient access point used when tracing connectivity, while splitting shields
# This value only means something when the emitter is on, and also shield pieces are thrown out pretty often
var shieldPiece

func _ready():
	# Rotate ourselves so our positive Z is pointing in the way the player is facing
	look_at(global_transform.origin - direction, source.normal)

func enable():
	if not shield:
		# Figure out what area we're filling
		var point = ShieldPiece.querySpots(
			get_world(),
			[shieldSpawn.global_transform.origin])[0]
		
		if point and "shield" in point:
			shield = point.shield
			shield.addEmitter(self)
			shield.spreadShield()
		else:
			shield = shieldScene.instance()
			shield.transform = shieldSpawn.global_transform
			shield.addEmitter(self)
			get_tree().root.add_child(shield)

func disable():
	if shield:
		shield.removeEmitter(self)
		shield.splitShield()
		shield = null
		shieldPiece = null

func setDirection(dir):
	direction = dir

func circuitPowerChanged(s_circuit, power):
	# I don't know how async signals are, so I'll make sure nothing changed here
	if circuit == s_circuit:
		if power > 0:
			enable()
		elif circuit.capacity == 0:
			disable()
		else:
			enable()

func changeCircuit(newCircuit):
	var oldCircuit = circuit
	circuit = newCircuit
	if circuit:
		circuit.connect("power_updated", self, "circuitPowerChanged")
		circuit.addSink(self)
	else:
		disable()
		if oldCircuit:
			oldCircuit.disconnect("power_updated", self, "circuitPowerChanged")
			oldCircuit.removeSink(self)
