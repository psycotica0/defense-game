extends StaticBody

const shieldScene = preload("res://Shield.tscn")

onready var shieldSpawn = $ShieldSpawn
onready var heat = $Heat
onready var health = $Health

var shield
var direction

var source
var circuit
var demand = 10

enum State {OFF, ON, VENTING}
var currentState

# This is a convenient access point used when tracing connectivity, while splitting shields
# This value only means something when the emitter is on, and also shield pieces are thrown out pretty often
var shieldPiece

func _ready():
	# Rotate ourselves so our positive Z is pointing in the way the player is facing
	look_at(global_transform.origin - direction, source.normal)
	changeState(State.OFF)

func changeState(newState):
	if currentState == newState:
		return
	
	currentState = newState
	
	match currentState:
		State.OFF, State.VENTING:
			disable()
		State.ON:
			enable()

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
		# We don't take damage while the shield is up
		# The shield takes damage, which is passed to us as heat
		health.invulnerable = true

func disable():
	if shield:
		shield.removeEmitter(self)
		shield.splitShield()
		shield = null
		shieldPiece = null
		health.invulnerable = false

func setDirection(dir):
	direction = dir

func circuitPowerChanged(s_circuit, power):
	# I don't know how async signals are, so I'll make sure nothing changed here
	# Also, if we're venting then power status doesn't matter, we're off either way
	if circuit == s_circuit and currentState != State.VENTING:
		if circuit.capacity == 0:
			changeState(State.OFF)
		else:
			changeState(State.ON)

func changeCircuit(newCircuit):
	var oldCircuit = circuit
	circuit = newCircuit
	if circuit:
		circuit.connect("power_updated", self, "circuitPowerChanged")
		circuit.addSink(self)
	else:
		changeState(State.OFF)
		if oldCircuit:
			oldCircuit.disconnect("power_updated", self, "circuitPowerChanged")
			oldCircuit.removeSink(self)
	heat.changeCircuit(circuit)
	health.changeCircuit(circuit)

func shieldDamage(damage):
	heat.heat(damage)

func _on_Heat_state_change(state):
	if state == Heat.State.VENTING:
		changeState(State.VENTING)
	elif currentState == State.VENTING:
		if circuit and circuit.capacity > 0:
			changeState(State.ON)
		else:
			changeState(State.OFF)

func _on_Health_dead():
	if source:
		# Tell our wire to get rid of us
		source.removeDependent()
