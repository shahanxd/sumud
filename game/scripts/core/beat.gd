extends Node2D
class_name Beat
## One playable stretch of a day: the beach, the street, the roof at dusk, the first strike.
## The day runner instances beats one after another; a beat calls finish() when its own
## scene is done and hands back what the next beat should know (what is carried, what
## happened). Beats never load each other.

signal finished(result: Dictionary)

## Shown on the chapter card if this beat opens a day, and used by the notebook.
@export var title := ""
## Which palette phase this beat starts in: morning, noon, dusk, night, siege.
@export var phase := "morning"

var context: Dictionary = {}
var _done := false


## Called by the runner after the scene is in the tree. Override to place the player,
## read what is carried, and start the beat's own script.
func begin(ctx: Dictionary) -> void:
	context = ctx


## Called by the beat when it is over. Safe to call twice; only the first counts.
func finish(result: Dictionary = {}) -> void:
	if _done:
		return
	_done = true
	finished.emit(result)


## The player node of this beat, if it has one. Bots and the camera rig use it.
func player() -> Player:
	return get_node_or_null("Player") as Player


## "Hold to tie": waits until `action` has been held for `seconds` in total while `near`
## is true (releasing pauses the fill, it never resets). Reports progress 0..1 through
## `on_progress` for a ring or a stitch drawing. In bot mode it needs 0.25 s. Awaitable.
func hold_action(action: String, seconds: float, near: Callable, on_progress: Callable = Callable()) -> void:
	var need := 0.25 if Day.bot_mode else seconds
	var t := 0.0
	while t < need:
		await get_tree().physics_frame
		if Input.is_action_pressed(action) and near.call():
			t += get_physics_process_delta_time()
			if on_progress.is_valid():
				on_progress.call(clampf(t / need, 0.0, 1.0))
	if on_progress.is_valid():
		on_progress.call(1.0)


## The adhan as a phase turn: a short sound-led transition inside one continuous day. No
## recording exists yet (the founder records it), so today it is the colour phase moving
## over `seconds` and the loops dipping; the hook is here so the recording drops in.
func adhan(day: int, to_phase: String, seconds: float = 6.0) -> void:
	Look.set_phase(day, to_phase, 0.5 if Day.bot_mode else seconds)
	await get_tree().create_timer(0.1 if Day.bot_mode else seconds * 0.5).timeout
