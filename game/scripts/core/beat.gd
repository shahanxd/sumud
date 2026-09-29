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
