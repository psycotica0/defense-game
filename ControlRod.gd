extends Spatial

export(NodePath) var test1
export(NodePath) var test2

var controlledBots = []

enum STATE {HELD, PLACED}
var state = STATE.PLACED

class ControledBot:
	var bot
	var offset

func _ready():
	if test1:
		var bot = ControledBot.new()
		bot.bot = get_node(test1)
		bot.offset = ((bot.bot.global_transform.origin - global_transform.origin) / 10).round()
		controlledBots.append(bot)
	if test2:
		var bot = ControledBot.new()
		bot.bot = get_node(test2)
		bot.offset = ((bot.bot.global_transform.origin - global_transform.origin) / 10).round()
		controlledBots.append(bot)

func pickup():
	for bot in controlledBots:
		bot.bot.changeState(BaseRobot.STATE.PACKING)

func putDown():
	for bot in controlledBots:
		bot.bot.move_to(global_transform.origin + (10 * bot.offset))

# This is a hack for testing
func clicked(place):
	if state == STATE.HELD:
		global_transform.origin = place * 10
		putDown()
		state = STATE.PLACED
	elif state == STATE.PLACED:
		pickup()
		state = STATE.HELD
