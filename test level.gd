extends Spatial

var wire_scene = preload("res://Wires.tscn")

var allWires = {}
var proposal = []
 
func _ready():
	pass

func startWire():
	proposal.clear()

func wireStep(pos, normal):
	var coord = [pos, normal]
	if proposal.back() != coord:
		var prev = proposal.back()
		proposal.push_back([pos, normal])
		var wire = addWire(pos, normal)
		wire.startPropose()
		if prev: # This isn't the first item, so we're making a connection
			var prevWire = allWires.get(prev)
			var diff = coord[0] - prev[0]
			print(coord, prev, diff)
			wire.propose(diff)
			prevWire.propose(-diff)

func finishWire():
	#for p in proposal:
	#	addWire(p[0], p[1])
	proposal.clear()

func addWire(pos, normal):
	var existing = allWires.get([pos, normal])
	if existing:
		print("Existing")
		return existing
	else:
		print("New one")
		var new_wires = wire_scene.instance()
		allWires[[pos, normal]] = new_wires
		get_tree().root.add_child(new_wires)
		new_wires.setPosition(pos, normal)
		return new_wires

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
