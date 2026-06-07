extends Node2D

var scroll_x : float = 0.0
var speed    : float = 480.0

const W  : float = 1280.0
const H  : float = 720.0
const GY : float = 580.0

var stars          : Array = []
var buildings_far  : Array = []
var buildings_near : Array = []
var far_total_w    : float = 0.0
var near_total_w   : float = 0.0

func _ready():
	randomize()
	for _i in range(150):
		stars.append({
			"x":  randf() * W,
			"y":  18.0 + randf() * (H * 0.50),
			"r":  0.55 + randf() * 1.90,
			"b":  0.30 + randf() * 0.70,
			"sp": 0.055 + randf() * 0.055
		})

	var bx = 0.0
	while bx < W * 2.4:
		var bw = 30.0 + randf() * 80.0
		var bh = 35.0 + randf() * 130.0
		buildings_far.append({"x": bx, "w": bw, "h": bh})
		bx += bw + 3.0 + randf() * 10.0
	far_total_w = bx

	bx = 0.0
	while bx < W * 2.4:
		var bw = 38.0 + randf() * 95.0
		var bh = 60.0 + randf() * 165.0
		buildings_near.append({"x": bx, "w": bw, "h": bh, "win_seed": randi()})
		bx += bw + 2.0 + randf() * 7.0
	near_total_w = bx

func set_speed(s: float):
	speed = s

func _process(delta):
	scroll_x += speed * delta
	update()

func _draw():
	# Sky
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.02, 0.09, 1.0), true)

	# Subtle gradient bands near horizon
	for i in range(14):
		var t  = float(i) / 14.0
		var gy = H * 0.28 + t * (GY * 0.72)
		var a  = t * t * 0.18
		draw_rect(Rect2(0, gy, W, H * 0.05), Color(0.06, 0.04, 0.22, a), true)

	# Stars
	for st in stars:
		var sx = fmod(st["x"] + scroll_x * st["sp"], W + 4)
		if sx < 0: sx += W + 4
		var tw = 0.62 + 0.38 * sin(scroll_x * 0.0028 + st["x"] * 0.73)
		draw_circle(Vector2(sx, st["y"]), st["r"],
					Color(0.72, 0.88, 1.0, st["b"] * tw))

	# Horizon glow
	for i in range(10):
		var t  = float(i) / 10.0
		var gy = GY - 58.0 + t * 58.0
		draw_rect(Rect2(0, gy, W, 6), Color(0.14, 0.30, 0.90, (1.0 - t) * 0.14), true)

	# Far city silhouette
	_draw_buildings(buildings_far, scroll_x * 0.16, far_total_w,
		Color(0.04, 0.03, 0.16, 1.0), Color(0.08, 0.15, 0.38, 0.0))

	# Near city silhouette
	_draw_buildings(buildings_near, scroll_x * 0.42, near_total_w,
		Color(0.03, 0.025, 0.12, 1.0), Color(0.12, 0.26, 0.55, 0.40))

	# Ground grid — perspective rays converging to single vanishing point
	_draw_grid()

	# Ground strip
	draw_rect(Rect2(0, GY - 2, W, 5), Color(0.30, 0.62, 1.0, 1.0),  true)
	draw_rect(Rect2(0, GY + 3, W, 2), Color(0.18, 0.44, 0.90, 0.65), true)
	draw_rect(Rect2(0, GY - 6, W, 4), Color(0.55, 0.82, 1.0, 0.28),  true)

func _draw_buildings(buildings: Array, offset: float, total_w: float,
		fill: Color, win_col: Color):
	if total_w <= 0: return
	for b in buildings:
		var bx = fmod(b["x"] - offset + total_w * 4.0, total_w)
		var by = GY - b["h"]
		draw_rect(Rect2(bx, by, b["w"], b["h"]), fill, true)
		if win_col.a > 0.05 and b["w"] > 22 and b["h"] > 35 and b.has("win_seed"):
			var seed = b["win_seed"]
			var cols = max(1, int(b["w"] / 15))
			var rows = max(1, int(b["h"] / 20))
			for r in range(rows):
				for c in range(cols):
					var idx = (seed ^ (r * 97 + c * 31)) & 0xFF
					if idx > 100: continue
					var wx = bx + 5.0 + c * 15.0
					var wy = by + 7.0 + r * 20.0
					if wx + 6 > bx + b["w"] - 4: continue
					if wy + 8 > by + b["h"] - 5: continue
					var flicker = 0.55 + 0.45 * sin(scroll_x * 0.006 + wx * 0.11 + wy * 0.17)
					draw_rect(Rect2(wx, wy, 6, 8),
						Color(win_col.r, win_col.g, win_col.b, win_col.a * flicker), true)

func _draw_grid():
	# Single vanishing point at screen centre — no symmetry seam
	var vp_x = W * 0.50
	var vp_y = GY - 46.0
	var gc   = Color(0.18, 0.40, 0.88, 1.0)

	# Horizontal perspective bands
	for i in range(8):
		var t  = float(i) / 7.0
		var yy = lerp(vp_y, GY, t * t)
		var a  = lerp(0.07, 0.28, t)
		draw_line(Vector2(0, yy), Vector2(W, yy), Color(gc.r, gc.g, gc.b, a), 1.0)

	# Perspective rays — scrolling tile offset so they move with the world
	var ray_count = 16
	var tile_w    = W / float(ray_count - 1)
	var raw_off   = fmod(scroll_x * 0.50, tile_w)
	for i in range(ray_count + 2):
		var gx     = (float(i) - 1.0) * tile_w - raw_off
		var edge_t = abs((gx / W) - 0.5) * 2.0
		var a      = lerp(0.20, 0.04, edge_t * edge_t)
		draw_line(Vector2(vp_x, vp_y), Vector2(gx, GY),
				  Color(gc.r, gc.g, gc.b, a), 1.0)
