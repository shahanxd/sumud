extends Node2D
class_name Figure
## A person drawn from a few bones, in silhouette, every frame. Owners (Player, Npc) set the
## pose, the walk phase and what the hands hold; the figure does the rest: a planted walk
## cycle, breathing, carry poses, a headscarf whose tail rides the wind, a dress hem that
## sways, an elder's stoop and cane. Drawn facing +x; the owner flips scale.x to face the
## other way. Origin at the feet. Every point is a fraction of the figure's height, so the
## same rig gives a child, an adult and an elder.

enum Pose { STAND, WALK, CRAWL, SIT }

const H_ADULT := 132.0
const TAIL_SEGMENTS := 5

@export_enum("child", "adult", "elder") var build := 1
@export var headscarf := false
@export_enum("none", "short", "long") var dress := 0
@export var cane := false
@export var color := Color(0.09, 0.08, 0.10)
@export var eye_color := Color(1.0, 0.85, 0.6)
@export var eyes := true
## How far the far arm and leg lift toward grey, so the walk reads inside a silhouette.
@export var depth_lift := 0.10
## A Node2D under this one, moved to the leading hand each frame; carried things hang from it.
@export var hand_path: NodePath = ^"Hand"

var pose := Pose.STAND
## Walk cycle in radians; the owner advances it with speed.
var phase := 0.0
## 0 still .. 1 full run: swing and lean scale with it.
var stride := 0.0
## -1 nothing, 0 light (one hand), 1 heavy (both hands low), 2 two-handed (arms forward).
var load := -1
## Leading arm raised (flying the kite).
var arm_up := false
var airborne := false

var _t := randf() * 10.0
var _p: Dictionary = {}
var _tail: Array[Vector2] = []
var _tail_prev: Array[Vector2] = []
var _hand: Node2D
var _wind: Node


func _ready() -> void:
	_hand = get_node_or_null(hand_path) as Node2D
	_wind = get_node_or_null("/root/Wind")
	_p = _pose_points()
	var anchor: Vector2 = _p["scarf_anchor"]
	for i in TAIL_SEGMENTS + 1:
		_tail.append(anchor + Vector2(-0.2, 1.0).normalized() * _tail_len() * i)
	_tail_prev = _tail.duplicate()


func height() -> float:
	var f: float = [0.80, 1.0, 0.92][build]
	return H_ADULT * f


func _tail_len() -> float:
	return 0.062 * height()


func _process(delta: float) -> void:
	_t += delta
	_p = _pose_points()
	if _hand:
		_hand.position = _p["wrist0"]
	if headscarf:
		_step_tail(delta)
	queue_redraw()


## Verlet ribbon hanging from the back of the scarf, blown by the day's wind.
func _step_tail(delta: float) -> void:
	var H := height()
	var wind := Vector2.ZERO
	if _wind:
		var w: Vector2 = _wind.call("sample", global_position)
		wind = global_transform.affine_inverse().basis_xform(w)
	var gust := wind.length() / 140.0
	var dt := minf(delta, 0.05)
	for i in range(1, TAIL_SEGMENTS + 1):
		var vel := (_tail[i] - _tail_prev[i]) * 0.88
		_tail_prev[i] = _tail[i]
		var flutter := Vector2(sin(_t * 13.0 + i * 1.7), cos(_t * 17.0 + i * 2.3)) * 900.0 * gust
		var force := Vector2(0.0, 9.0 * H) + wind * 4.0 + flutter
		_tail[i] += vel + force * dt * dt
	_tail[0] = _p["scarf_anchor"]
	_tail_prev[0] = _tail[0]
	var len := _tail_len()
	for _iter in 3:
		for i in range(1, TAIL_SEGMENTS + 1):
			var d := _tail[i] - _tail[i - 1]
			if d.length_squared() < 0.0001:
				d = Vector2(0.0, 1.0)
			_tail[i] = _tail[i - 1] + d.normalized() * len


## Solves the pose into named points. Index 0 is the near side (drawn last), 1 the far side.
func _pose_points() -> Dictionary:
	var H := height()
	var elder := build == 2
	var breath := sin(_t * 1.6) * 0.004 * H
	var A := (0.12 + 0.55 * stride) * (0.6 if elder else 1.0)
	var K := 0.15 + 0.90 * stride
	var hip_w := 0.075 * H
	var sh_w := (0.115 if build == 1 else 0.10) * H
	var head_r := 0.072 * H
	var thigh_len := 0.26 * H
	var shin_len := 0.25 * H
	var upper_len := 0.19 * H
	var fore_len := 0.17 * H

	var pelvis := Vector2(0.0, -0.50 * H)
	var chest := Vector2(0.0, -0.82 * H)
	var head := Vector2(0.0, -(H - head_r))
	var thigh_a: Array[float] = [0.03, -0.03]
	var knee_k: Array[float] = [0.02, 0.02]
	var arm_a: Array[float] = [0.06, 0.04]
	var elbow_k: Array[float] = [0.15, 0.12]
	var plant := true
	var knees: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
	var ankles: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
	var elbows: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
	var wrists: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
	var explicit_limbs := false

	match pose:
		Pose.WALK:
			for i in 2:
				var p := phase + PI * i
				thigh_a[i] = A * sin(p)
				knee_k[i] = K * maxf(0.0, cos(p))
				var q := p + PI
				arm_a[i] = 0.6 * A * sin(q)
				elbow_k[i] = 0.30 + 0.35 * stride + 0.25 * maxf(0.0, sin(q))
			var lean := 0.04 + 0.10 * stride
			chest.x += lean * 0.32 * H
			head.x += lean * 0.45 * H
			var bob := absf(cos(phase)) * 0.02 * H * stride
			pelvis.y -= bob
			chest.y -= bob
			head.y -= bob
		Pose.STAND:
			chest.y += breath
			head.y += breath * 1.3
			arm_a[0] += breath * 3.0 / H
		Pose.CRAWL:
			plant = false
			explicit_limbs = true
			pelvis = Vector2(-0.05 * H, -0.30 * H)
			chest = Vector2(0.30 * H, -0.33 * H)
			head = chest + Vector2(0.15 * H, -0.05 * H)
			for i in 2:
				var s := sin(phase + PI * i) * 0.06 * H * maxf(stride, 0.0)
				knees[i] = pelvis + Vector2(0.04 * H + s, 0.27 * H)
				ankles[i] = knees[i] + Vector2(-0.24 * H, 0.0)
				elbows[i] = chest + Vector2(0.03 * H - s * 0.5, 0.17 * H)
				wrists[i] = chest + Vector2(0.09 * H - s, 0.32 * H)
		Pose.SIT:
			plant = false
			explicit_limbs = true
			pelvis = Vector2(0.0, -0.10 * H)
			chest = Vector2(0.03 * H, -0.42 * H + breath)
			head = Vector2(0.05 * H, -0.42 * H - 0.10 * H - head_r + breath * 1.3)
			for i in 2:
				var side := 0.01 * H * (1 - 2 * i)
				knees[i] = pelvis + Vector2(0.20 * H + side, -0.16 * H)
				ankles[i] = knees[i] + Vector2(0.06 * H, 0.23 * H)
				elbows[i] = chest + Vector2(0.02 * H, 0.18 * H)
				wrists[i] = knees[i] + Vector2(0.0, -0.02 * H)

	if airborne and not explicit_limbs:
		plant = false
		thigh_a = [0.55, -0.25]
		knee_k = [0.9, 0.45]
		arm_a = [0.5, 0.3]
		elbow_k = [0.4, 0.4]

	if not explicit_limbs:
		match load:
			0:
				arm_a[0] = 0.40
				elbow_k[0] = 1.1
			1:
				arm_a = [0.22, 0.22]
				elbow_k = [0.1, 0.1]
				chest.x -= 0.02 * H
				if pose == Pose.STAND:
					thigh_a = [0.08, -0.08]
			2:
				arm_a = [1.30, 1.30]
				elbow_k = [0.25, 0.25]
				chest.x += 0.02 * H
		if arm_up:
			arm_a[0] = 2.35
			elbow_k[0] = 0.15
		if cane:
			arm_a[1] = 0.12
			elbow_k[1] = 0.55
	if elder and pose != Pose.CRAWL:
		chest.x += 0.05 * H
		head.x += 0.10 * H
		head.y += 0.04 * H

	if not explicit_limbs:
		for i in 2:
			var hip := pelvis + Vector2(0.01 * H * (1 - 2 * i), 0.0)
			var ta := thigh_a[i]
			var sa := ta - knee_k[i]
			knees[i] = hip + Vector2(sin(ta), cos(ta)) * thigh_len
			ankles[i] = knees[i] + Vector2(sin(sa), cos(sa)) * shin_len
			var aa := arm_a[i]
			var fa := aa + elbow_k[i]
			elbows[i] = chest + Vector2(sin(aa), cos(aa)) * upper_len
			wrists[i] = elbows[i] + Vector2(sin(fa), cos(fa)) * fore_len

	if plant:
		# Keep the lower foot on the ground, whatever the legs are doing.
		var lowest := maxf(ankles[0].y, ankles[1].y)
		var shift := -0.03 * H - lowest
		pelvis.y += shift
		chest.y += shift
		head.y += shift
		for i in 2:
			knees[i].y += shift
			ankles[i].y += shift
			elbows[i].y += shift
			wrists[i].y += shift

	var scarf_r := head_r * 1.22
	return {
		"H": H, "head_r": head_r, "hip_w": hip_w, "sh_w": sh_w,
		"pelvis": pelvis, "chest": chest, "head": head,
		"knee0": knees[0], "knee1": knees[1], "ankle0": ankles[0], "ankle1": ankles[1],
		"elbow0": elbows[0], "elbow1": elbows[1], "wrist0": wrists[0], "wrist1": wrists[1],
		"scarf_anchor": head + Vector2.from_angle(-3.75) * scarf_r,
	}


func _draw() -> void:
	if _p.is_empty():
		return
	var H: float = _p["H"]
	var head_r: float = _p["head_r"]
	var hip_w: float = _p["hip_w"]
	var sh_w: float = _p["sh_w"]
	var pelvis: Vector2 = _p["pelvis"]
	var chest: Vector2 = _p["chest"]
	var head: Vector2 = _p["head"]
	var far := color.lerp(Color(0.55, 0.55, 0.60), depth_lift)

	# Far limbs first, so the near ones read in front.
	_limb(pelvis, _p["knee1"], _p["ankle1"], 0.085 * H, 0.065 * H, far)
	_foot(_p["ankle1"], H, far)
	_limb(chest, _p["elbow1"], _p["wrist1"], 0.06 * H, 0.05 * H, far)
	draw_circle(_p["wrist1"], 0.028 * H, far)
	if cane:
		var w1: Vector2 = _p["wrist1"]
		draw_line(w1, Vector2(w1.x + 0.04 * H, -0.004 * H), far, 0.022 * H, true)

	# Torso: a tapered slab from shoulders to hips with rounded shoulders.
	var axis := (pelvis - chest).normalized()
	var n := axis.orthogonal()
	var torso := PackedVector2Array([
		chest + n * sh_w, chest - n * sh_w, pelvis - n * hip_w * 1.1, pelvis + n * hip_w * 1.1])
	draw_colored_polygon(torso, color)
	draw_circle(chest + n * sh_w * 0.65, sh_w * 0.36, color)
	draw_circle(chest - n * sh_w * 0.65, sh_w * 0.36, color)
	draw_circle(pelvis, hip_w * 1.05, color)
	_draw_dress(H, chest, pelvis, sh_w)

	# Near leg, neck and head.
	_limb(pelvis, _p["knee0"], _p["ankle0"], 0.085 * H, 0.065 * H, color)
	_foot(_p["ankle0"], H, color)
	draw_line(chest, head, color, 0.07 * H, true)
	draw_circle(head, head_r, color)
	if not headscarf and build == 0:
		# A child's hair: a fuller crown and a nape.
		draw_circle(head + Vector2(-0.12 * head_r, -0.10 * head_r), head_r * 1.12, color)
	if headscarf:
		_draw_scarf(H, head, head_r, chest, sh_w)
	if eyes:
		var e := 0.036 * H
		for k in [0.28, 0.70]:
			var c := head + Vector2(head_r * k, -0.2 * head_r)
			draw_rect(Rect2(c - Vector2(e * 0.5, e * 0.5), Vector2(e, e)), eye_color)

	# Near arm last, in front of everything; what it carries is a child node, drawn after.
	_limb(chest, _p["elbow0"], _p["wrist0"], 0.06 * H, 0.05 * H, color)
	draw_circle(_p["wrist0"], 0.028 * H, color)


func _limb(a: Vector2, b: Vector2, c: Vector2, w1: float, w2: float, col: Color) -> void:
	draw_line(a, b, col, w1, true)
	draw_circle(b, w1 * 0.5, col)
	draw_line(b, c, col, w2, true)
	draw_circle(c, w2 * 0.5, col)


func _foot(ankle: Vector2, H: float, col: Color) -> void:
	var y := ankle.y + 0.012 * H
	draw_line(Vector2(ankle.x - 0.015 * H, y), Vector2(ankle.x + 0.075 * H, y), col, 0.035 * H, true)


func _draw_dress(H: float, chest: Vector2, pelvis: Vector2, sh_w: float) -> void:
	if dress == 0 or pose == Pose.CRAWL:
		return
	var sway := sin(phase) * 0.02 * H * stride
	var pts := PackedVector2Array()
	pts.append(chest + Vector2(-sh_w * 0.9, 0.03 * H))
	pts.append(chest + Vector2(sh_w * 0.9, 0.03 * H))
	if pose == Pose.SIT:
		var knee: Vector2 = _p["knee0"]
		var ankle: Vector2 = _p["ankle0"]
		if dress == 2:
			pts.append(knee + Vector2(0.04 * H, -0.03 * H))
			pts.append(ankle + Vector2(0.05 * H, 0.0))
			pts.append(pelvis + Vector2(-0.14 * H, 0.09 * H))
		else:
			pts.append(knee + Vector2(-0.02 * H, 0.0))
			pts.append(pelvis + Vector2(-0.12 * H, 0.08 * H))
	elif dress == 2:
		pts.append(Vector2(pelvis.x + 0.17 * H + sway * 0.5, -0.025 * H))
		pts.append(Vector2(pelvis.x - 0.17 * H + sway, -0.025 * H))
	else:
		pts.append(pelvis + Vector2(0.15 * H + sway * 0.5, 0.16 * H))
		pts.append(pelvis + Vector2(-0.15 * H + sway, 0.16 * H))
	draw_colored_polygon(pts, color)


func _draw_scarf(H: float, head: Vector2, head_r: float, chest: Vector2, sh_w: float) -> void:
	var R := head_r * 1.22
	var pts := PackedVector2Array()
	for k in 11:
		var ang := lerpf(-1.05, -3.85, k / 10.0)
		pts.append(head + Vector2.from_angle(ang) * R)
	pts.append(Vector2(chest.x - sh_w - 0.02 * H, chest.y + 0.05 * H))
	pts.append(Vector2(chest.x + sh_w * 0.85, chest.y + 0.05 * H))
	pts.append(head + Vector2(head_r * 0.8, head_r * 0.95))
	draw_colored_polygon(pts, color)
	# The tail: segments that taper to the end (lines, not a strip, so a fold cannot make
	# a self-intersecting polygon).
	for i in range(1, _tail.size()):
		var w := lerpf(0.05 * H, 0.014 * H, float(i) / float(TAIL_SEGMENTS))
		draw_line(_tail[i - 1], _tail[i], color, w, true)
		draw_circle(_tail[i], w * 0.5, color)
