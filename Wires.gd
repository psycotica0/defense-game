extends Spatial

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

func startPropose():
	$Proposed/Hub.visible = true

func proposePosX():
	$Proposed/PosX.visible = true

func proposeNegX():
	$Proposed/NegX.visible = true

func proposePosZ():
	$Proposed/PosZ.visible = true

func proposeNegZ():
	$Proposed/NegZ.visible = true
