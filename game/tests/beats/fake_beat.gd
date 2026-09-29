extends Beat
## A beat for tests: finishes after a few frames and passes one value forward.

@export var frames_to_live := 5
@export var result_key := "fake"

var began := false


func begin(ctx: Dictionary) -> void:
	super.begin(ctx)
	began = true
	for _i in frames_to_live:
		await get_tree().physics_frame
	finish({result_key: int(ctx.get(result_key, 0)) + 1})
