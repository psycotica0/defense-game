extends Node

class_name Health

export var max_health = 100.0
export var healing_rate = 10
const ENERGY_TO_HEAL = 10

var health = max_health
var reportedHealth = health

var demand = 0

# If this item has a circuit it will attach to it
# While attached it will draw power to heal itself
var circuit

var currentState

enum State {FULL, DAMAGED, CHARGING, DEAD}

# When this is set, the system does its normal thing, but no new damage comes in
var invulnerable = false

signal health_changed(health)
signal dead()

func _ready():
	changeState(State.FULL)

func changeState(newState):
	if newState == currentState:
		return
	
	match newState:
		State.FULL:
			health = max_health
			updateDemand(0)
		State.DAMAGED:
			# It's important demand doesn't change here
			# If demand goes to 0 in response to a circuit being overloaded, we could hit an oscillation state
			# So if we're currently disconnected, then it doesn't matter
			# And if we're connected and brown'd out, then we need to stay that way
			pass
		State.CHARGING:
			updateDemand(ENERGY_TO_HEAL)
		State.DEAD:
			health = 0
			updateDemand(0)
			emit_signal("dead")
	
	currentState = newState

func changeCircuit(newCircuit):
	var oldCircuit = circuit
	circuit = newCircuit
	if circuit:
		circuit.connect("power_updated", self, "circuitPowerChanged")
		circuit.addSink(self)
	else:
		if currentState == State.CHARGING:
			changeState(State.DAMAGED)
		
		if oldCircuit:
			oldCircuit.disconnect("power_updated", self, "circuitPowerChanged")
			oldCircuit.removeSink(self)

func circuitPowerChanged(s_circuit, power):
	if s_circuit != circuit:
		return
	
	if power <= 0:
		if currentState == State.CHARGING:
			changeState(State.DAMAGED)
	else:
		if currentState == State.DAMAGED:
			changeState(State.CHARGING)

func _physics_process(delta):
	match currentState:
		State.FULL:
			if health < max_health:
				if circuit and circuit.power > 0:
					changeState(State.CHARGING)
				else:
					changeState(State.DAMAGED)
		State.DAMAGED:
			if health <= 0:
				changeState(State.DEAD)
		State.CHARGING:
			health += healing_rate * delta
			
			if health <= 0:
				changeState(State.DEAD)
			elif health >= max_health:
				changeState(State.FULL)
		State.DEAD:
			pass
	
	reportHealth(health)

func reportHealth(reported):
	if reportedHealth != reported:
		reportedHealth = reported
		emit_signal("health_changed")

func updateDemand(d):
	demand = d
	if circuit:
		circuit.call_deferred("updateDemand")

func receiveDamage(d):
	if not invulnerable:
		health -= d
