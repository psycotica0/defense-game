extends Spatial

export(NodePath) var test1
export(NodePath) var test2

var controlledBots = []

enum STATE {HELD, PLACED}
var state = STATE.PLACED

class ControledBot:
	var bot
	var offset
	var orientation

func _ready():
	if test1:
		add_bot(test1)
	if test2:
		add_bot(test2)

func add_bot(target):
	var bot = ControledBot.new()
	bot.bot = get_node(target)
	bot.offset = (to_local(bot.bot.global_transform.origin) / 10).round()
	bot.orientation = (bot.bot.to_global(Vector3(0,0,1)) - bot.bot.to_global(Vector3(0,0,0))) - (to_global(Vector3(0,0,1)) - to_global(Vector3(0,0,0)))
	controlledBots.append(bot)

func pickup():
	for bot in controlledBots:
		bot.bot.changeState(BaseRobot.STATE.PACKING)

func putDown():
	for bot in controlledBots:
		bot.bot.move_to(
			to_global(10 * bot.offset),
			to_global(Vector3(0,0,1) + bot.orientation) - to_global(Vector3(0,0,0))
		)

# This is a hack for testing
func clicked(place, orientation):
	if state == STATE.HELD:
		global_transform.origin = place * 10
		look_at(global_transform.origin - orientation, Vector3.UP)
		putDown()
		state = STATE.PLACED
	elif state == STATE.PLACED:
		pickup()
		state = STATE.HELD
