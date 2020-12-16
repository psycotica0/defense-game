extends Spatial

var position
var normal

const OFFSET = Vector3(5, 5, 5)

const UP = Vector3.UP
const DOWN = Vector3.DOWN
const RIGHT = Vector3.RIGHT
const LEFT = Vector3.LEFT
const FORWARD = Vector3.FORWARD
const BACK = Vector3.BACK

func _ready():
	$Committed/Hub.visible = false
	$Committed/PosZ.visible = false
	$Committed/NegZ.visible = false
	$Committed/PosX.visible = false
	$Committed/NegX.visible = false
	
	$Proposed/Hub.visible = false
	$Proposed/PosZ.visible = false
	$Proposed/NegZ.visible = false
	$Proposed/PosX.visible = false
	$Proposed/NegX.visible = false

func setPosition(pos, norm):
	position = pos
	normal = norm
	var tile_position = pos * 10 + OFFSET
	translation = tile_position
	match normal:
		UP: # This is floor, do nothing
			pass
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

func startPropose():
	$Proposed/Hub.visible = true

func propose(direction, otherNormal):
	if direction == Vector3.ZERO:
		# If we're not going anywhere, then we should instead move towards the other tile's normal
		direction = otherNormal
	
	# Since these are integer values, the only way to get 2 is if it's 1 in two places.
	# 2 in one place will get me 4, because it's squared, and we don't have imaginary values
	# So I think we're ok here.
	# So if I've moved between two places that differ by 1 in two axis, then I think that's an outside corner
	if direction.length_squared() == 2.0:
		direction = -otherNormal
		
	match direction:
		RIGHT:
			match normal:
				UP, DOWN, BACK, FORWARD:
					$Proposed/NegX.visible = true
		LEFT:
			match normal:
				UP, DOWN, BACK, FORWARD:
					$Proposed/PosX.visible = true
		FORWARD:
			match normal:
				UP, LEFT, RIGHT:
					$Proposed/PosZ.visible = true
				DOWN:
					$Proposed/NegZ.visible = true
		BACK:
			match normal:
				UP, LEFT, RIGHT:
					$Proposed/NegZ.visible = true
				DOWN:
					$Proposed/PosZ.visible = true
		UP:
			match normal:
				RIGHT:
					$Proposed/PosX.visible = true
				LEFT:
					$Proposed/NegX.visible = true
				BACK:
					$Proposed/PosZ.visible = true
				FORWARD:
					$Proposed/NegZ.visible = true
		DOWN:
			match normal:
				RIGHT:
					$Proposed/NegX.visible = true
				LEFT:
					$Proposed/PosX.visible = true
				BACK:
					$Proposed/NegZ.visible = true
				FORWARD:
					$Proposed/PosZ.visible = true
