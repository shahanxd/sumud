extends Beat
## Day 1 on the beach, prototype cut: Sami's kite string is caught on Abu Fadi's stall
## roof, too high to jump to. Layla flies her kite, snags the string with it, reels it
## down and brings it to Sami. The beat ends when he has it.

@onready var player_node: Player = $Player
@onready var kite: Kite = $Kite
@onready var sami: Npc = $Sami
@onready var string_spool: Carryable = $StringSpool
@onready var hint: Label = $HUD/Hint

var asked := false
var delivered := false


func _ready() -> void:
	title = "The kites"
	phase = "morning"
	Look.dress()
	sami.talked.connect(_on_sami_talked)
	sami.approached.connect(_on_sami_approached)
	kite.hooked_item.connect(_on_hooked)


func begin(ctx: Dictionary) -> void:
	super.begin(ctx)
	# The Mediterranean and the onshore wind; Day 1 has no hum and no rumble.
	Sound.loop("sea_loop", "ambience", -4.0, 2.0)
	Sound.loop("wind_loop", "ambience", -8.0, 2.0)
	# Sami calls from down the beach, so the player knows where to go before anything else.
	hint.text = Say.text("beach.hint.find")
	Say.key("beach.sami.call", 4.0)


func _on_sami_approached(_npc: Npc) -> void:
	if not asked:
		_ask()


func _on_sami_talked(_npc: Npc) -> void:
	if not asked:
		_ask()


func _ask() -> void:
	asked = true
	await Say.key("beach.sami.string")
	hint.text = Say.text("beach.hint.fetch")


func _on_hooked(item: Carryable) -> void:
	if item == string_spool:
		Say.key("beach.layla.got_it", 2.0)


func _physics_process(_delta: float) -> void:
	if delivered or not asked:
		return
	var carried_to_sami := player_node.carried == string_spool and sami.player_near
	var spool_at_sami := not string_spool.held and string_spool.global_position.distance_to(sami.global_position) < 140.0
	if carried_to_sami or spool_at_sami:
		delivered = true
		_deliver()


func _deliver() -> void:
	if player_node.carried == string_spool:
		player_node.carried = null
	string_spool.drop(sami.global_position + Vector2(-30.0, 0.0))
	string_spool.hookable = false
	await Say.key("beach.sami.thanks")
	Notebook.write("beach_fetched_string", Say.text("notebook.beach.fetched", "en"), Say.text("notebook.beach.fetched", "ar"), {"act": true})
	finish({"kite_fetched": true})
