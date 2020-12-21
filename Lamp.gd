extends Spatial

onready var activeLight = $Spatial/ActiveLight
onready var inactiveLight = $Spatial/InactiveLight

var position
var normal
var circuitManager
var circuit
var source

const OFFSET = Vector3(5, 5, 5)

const UP = Vector3.UP
const DOWN = Vector3.DOWN
const RIGHT = Vector3.RIGHT
const LEFT = Vector3.LEFT
const FORWARD = Vector3.FORWARD
const BACK = Vector3.BACK

func _ready():
	deactivate()

func setPosition(pos, norm):
	position = pos
	normal = norm
	var tile_position = pos * 10 + OFFSET
	translation = tile_position
	match normal:
		UP: # This is floor. For hacky reasons, for now that means I need to move up
			translate(Vector3(0, 1, 0))
		DOWN: # Ceiling
			rotate_x(PI)
		LEFT: # This is wall
			rotate_z(PI/2)
		RIGHT:
			rotate_z(-PI/2)
		FORWARD:
			rotate_x(-PI/2)
		BACK:
			rotate_x(PI/2)

func _on_Area_area_entered(area):
	prints("Entered Lamp!", area, area.get_parent())
	source = area.get_parent()
	source.setDependent(self)

func _on_Area_area_exited(area):
	prints("Exit Lamp!", area, area.get_parent())
	source = null
	changeCircuit(null)

func changeCircuit(newCircuit):
	circuit = newCircuit
	if circuit:
		activate()
	else:
		deactivate()

func activate():
	activeLight.visible = true
	inactiveLight.visible = false

func deactivate():
	activeLight.visible = false
	inactiveLight.visible = true
