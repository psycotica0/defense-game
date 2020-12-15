extends Spatial

var wire_scene = preload("res://Wires.tscn")
 
func _ready():
	pass

func addWire(pos, normal):
	var new_wires = wire_scene.instance()
	var OFFSET = Vector3(5, 5, 5)
	get_tree().root.add_child(new_wires)
	var tile_position = pos * 10 + OFFSET
	new_wires.translation = tile_position
	match normal:
		Vector3.UP: # This is floor, do nothing
			pass
		Vector3.DOWN: # Ceiling
			new_wires.rotate_x(PI)
		Vector3.LEFT: # This is wall
			new_wires.rotate_z(PI/2)
		Vector3.RIGHT:
			new_wires.rotate_z(-PI/2)
		Vector3.FORWARD:
			new_wires.rotate_x(-PI/2)
		Vector3.BACK:
			new_wires.rotate_x(PI/2)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
