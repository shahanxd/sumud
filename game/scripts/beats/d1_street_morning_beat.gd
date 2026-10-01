extends D1StreetBeat
## Day 1, Scene 2: the street wakes. Layla leaves the home door at the left end and walks
## right toward the beach, through everyone's morning: Hajja Amina at her window next door,
## Abu Ahmad at the bakery, Abu Fadi and his panels, Um Samir sweeping the clinic step with
## Samir at her hem, the twins waiting mid-street with their kites. Lines are barks overheard
## in passing; none stops her. Past the twins, the children follow her. The beat ends at the
## top of the steps down to the sand.

## Just right of the foot of the outside stairs, under the home door.
const START := Vector2(420.0, 900.0)
## The top of the steps to the sand, past the last facade.
const FINISH_X := 4960.0
## Barks by the x Layla passes, in the street's own order from the home door: Hajja Amina
## hails her from the window next door as she sets off, then the doors down the street.
const MARKS: Array = [
	[460.0, "d1.s2.hajja.01"],
	[640.0, "d1.s2.layla.02"],
	[1000.0, "d1.s2.abu_ahmad.01"],
	[1450.0, "d1.s2.abu_fadi.01"],
	[2450.0, "d1.s2.um_samir.01"],
	[2800.0, "d1.s2.twin.01"],
	[2950.0, "d1.s2.twin.02"],
	[3100.0, "d1.s2.layla.01"],
]

var reached_sand := false


func _ready() -> void:
	title = "The street wakes"
	phase = "morning"
	super()


func begin(ctx: Dictionary) -> void:
	super.begin(ctx)
	layla.global_position = START
	layla.velocity = Vector2.ZERO
	layla.facing = 1
	# The wind between the houses, faint; the sea grows as she nears the steps.
	Sound.loop("wind_loop", "ambience", -16.0, 2.0)
	sea = Sound.loop("sea_loop", "ambience", sea_db_for(START.x), 0.0)
	set_marks(MARKS, false)
	# The controls line the street scene carries, then nothing: the street speaks for itself.
	clear_hint_in(3.0)


func _step(_delta: float) -> void:
	var x := layla.global_position.x
	if not twins_following and x > D1StreetDressing.TWINS_X + 40.0:
		twins_following = true
	if not reached_sand and x > FINISH_X:
		reached_sand = true
		hold_barks(true)
		hint.text = ""
		finish({"d1_twins": true})


func _on_bark(key: String) -> void:
	if key == "d1.s2.hajja.01":
		dressing.hajja_wave()
