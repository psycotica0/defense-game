extends Node

class_name Circuit

var identifier
var members = []

var sources = []
var capacity = 0

var sinks = []
var demand = 0

var power = 0

signal power_updated(circuit, power)

func join(item):
	members.push_back(item)

func addSource(source):
	sources.push_back(source)
	updateCapacity()

func removeSource(source):
	sources.erase(source)
	updateCapacity()

func updateCapacity():
	var newCap = 0
	for s in sources:
		newCap += s.capacity
	
	capacity = newCap
	prints("Circuit Capacity is now", capacity)
	updatePower()

func addSink(sink):
	sinks.push_back(sink)
	updateDemand()

func removeSink(sink):
	sinks.erase(sink)
	updateDemand()

func updateDemand():
	var newDemand = 0
	for s in sinks:
		newDemand += s.demand
	
	demand = newDemand
	prints("Demand is now", demand)
	updatePower()

func updatePower():
	power = capacity - demand
	emit_signal("power_updated", self, power)

# This tells us if this circuit should be deleted
func is_trivial():
	# The extra complexity is to account for the fact a circuit next to an open
	# switch is technically in its own circuit, but it does actually have
	# structure we'd like to preserve
	return members.size() == 0 or (
		members.size() == 1 and
		members[0].is_trivial()
	)
