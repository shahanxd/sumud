extends Beat
## The street, prototype cut: the water truck has stopped at the far end. Layla carries a
## 20-litre jerrycan home. Empty-handed she jumps the pit by the bakery; with the jerrycan
## the jump is gone, so the route changes: set the water down, fetch Abu Ahmad's plank,
## lay it across, and carry the water over. The beat ends at the home door.

@onready var player_node: Player = $Player
@onready var jerrycan: Carryable = $Jerrycan
@onready var plank: Plank = $Plank
@onready var door: Area2D = $HomeDoor
@onready var hint: Label = $HUD/Hint

var fell_in := false
var hinted := false
var delivered := false


func _ready() -> void:
	title = "Water"
	phase = "noon"
	Look.dress()
	plank.bridged.connect(func(_p): Notebook.write("street_plank_bridge", Say.text("notebook.street.plank", "en"), Say.text("notebook.street.plank", "ar")))
	_open()


func begin(ctx: Dictionary) -> void:
	super.begin(ctx)
	# The wind reaches the street faintly, between the houses.
	Sound.loop("wind_loop", "ambience", -16.0, 2.0)


func _open() -> void:
	await get_tree().physics_frame
	await Say.key("street.mama.water")


func _physics_process(_delta: float) -> void:
	if delivered:
		return
	# In the pit with the water: say the rule once, in Layla's voice.
	if not hinted and player_node.global_position.y > 950.0 and player_node.carried == jerrycan:
		hinted = true
		fell_in = true
		hint.text = Say.text("street.hint.plank")
		Say.key("street.layla.heavy", 2.5)
	if player_node.carried == jerrycan and door.overlaps_body(player_node):
		delivered = true
		_deliver()


func _deliver() -> void:
	player_node.carried = null
	jerrycan.drop(door.global_position + Vector2(-40.0, 0.0))
	await Say.key("street.mama.thanks")
	Notebook.write("street_water_home", Say.text("notebook.street.water", "en"), Say.text("notebook.street.water", "ar"), {"act": true})
	finish({"water": true, "used_plank": plank.is_bridge})
