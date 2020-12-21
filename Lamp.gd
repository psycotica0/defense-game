extends Spatial

onready var activeLight = $Spatial/ActiveLight
onready var inactiveLight = $Spatial/InactiveLight

func _ready():
	deactivate()

func _on_Area_area_entered(area):
	prints("Entered Lamp!", area, area.get_parent())
	activate()

func _on_Area_area_exited(area):
	prints("Exit Lamp!", area, area.get_parent())
	deactivate()

func activate():
	activeLight.visible = true
	inactiveLight.visible = false

func deactivate():
	activeLight.visible = false
	inactiveLight.visible = true
