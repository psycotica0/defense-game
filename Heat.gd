extends Node

class_name Heat

var demand = 0

# If this item has a circuit it will attach to it
# While attached it will draw power to heal itself
var circuit

var currentState

var currentHeat = 0

export var max_heat = 100.0
export var passive_cool_rate = 5.0
export var active_cool_rate = 10.0 # These don't add, it's one or the other
export var active_demand = 5.0

var powered = false

signal state_change(state)

enum State {
	PASSIVE,   # This state represents that the passive heat dissipation is enough
	ACTIVE,    # This represents the chiller running to try and remove heat
	VENTING,   # This represents the chiller's threshold was exceeded and it's recovering
}

func _ready():
	changeState(State.PASSIVE)

func changeState(newState):
	if newState == currentState:
		return
	
	currentState = newState
	
	match currentState:
		State.PASSIVE:
			updateDemand(0)
		State.ACTIVE, State.VENTING:
			updateDemand(active_demand)
	
	emit_signal("state_change", currentState)

func _physics_process(delta):
	match(currentState):
		State.PASSIVE:
			cool(passive_cool_rate * delta)
			if currentHeat > 0:
				changeState(State.ACTIVE)
		State.ACTIVE:
			if currentHeat < passive_cool_rate * delta:
				# We change the state here, but process as active
				# It's fine. It's one frame of "free cooling"
				# Meh
				changeState(State.PASSIVE)
			elif currentHeat == max_heat:
				changeState(State.VENTING)
			
			if powered:
				cool(active_cool_rate * delta)
			else:
				cool(passive_cool_rate * delta)
		State.VENTING:
			if powered:
				cool(active_cool_rate * delta)
			else:
				cool(passive_cool_rate * delta)
			
			if currentHeat == 0:
				changeState(State.PASSIVE)

func changeCircuit(newCircuit):
	var oldCircuit = circuit
	circuit = newCircuit
	if circuit:
		circuit.connect("power_updated", self, "circuitPowerChanged")
		circuit.addSink(self)
	else:
		powered = false
		
		if oldCircuit:
			oldCircuit.disconnect("power_updated", self, "circuitPowerChanged")
			oldCircuit.removeSink(self)

func cool(cool_rate):
	currentHeat = clamp(currentHeat - cool_rate, 0.0, max_heat)

func heat(heat_rate):
	cool(-heat_rate)

func circuitPowerChanged(s_circuit, power):
	if s_circuit != circuit:
		return
	
	powered = power > 0

func updateDemand(d):
	if demand == d:
		return
	
	demand = d
	if circuit:
		circuit.call_deferred("updateDemand")
