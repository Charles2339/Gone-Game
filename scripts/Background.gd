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

# Neon accent lights on ground
var accent_lights  : Array = []
const ACCENT_COUNT : int   = 12

func _ready():
	randomize()
	for _i in range(160):
		stars.append({
			"x":  randf() * W,
			"y":  14.0 + randf() * (H * 0.48),
			"r":  0.5 + randf() * 2.0,
			"b":  0.30 + randf() * 0.70,
			"sp": 0.04 + randf() * 0.04
		})

	# Far skyline
	var bx = 0.0
	while bx < W * 2.6:
		var bw = 28.0 + randf() * 82.0
		var bh = 32.0 + randf() * 140.0
		buildings_far.append({"x": bx, "w": bw, "h": bh})
		bx += bw + 2.0 + randf() * 10.0
	far_total_w = bx

	# Near skyline
	bx = 0.0
	while bx < W * 2.6:
		var bw = 36.0 + randf() * 100.0
		var bh = 55.0 + randf() * 175.0
		buildings_near.append({"x": bx, "w": bw, "h": bh, "win_seed": randi()})
		bx += bw + 2.0 + randf() * 8.0
	near_total_w = bx

	# Ground accent lights — fixed positions distributed across screen width
	for i in range(ACCENT_COUNT):
		var hue_roll = randf()
		var col : Color
		if hue_roll < 0.33:
			col = Color(0.30, 0.60, 1.00, 1.0)   # blue
		elif hue_roll < 0.66:
			col = Color(0.55, 0.20, 1.00, 1.0)   # purple
		else:
			col = Color(0.10, 0.80, 0.90, 1.0)   # cyan
		accent_lights.append({
			"x_phase": float(i) / float(ACCENT_COUNT),
			"col": col,
			"flicker_phase": randf() * TAU
		})

func set_speed(s: float):
	speed = s

func _process(delta):
	scroll_x += speed * delta
	update()

func _draw():
	# Sky gradient — deep navy to near-black
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.02, 0.10, 1.0), true)

	# Subtle purple/blue atmosphere bands near horizon
	for i in range(18):
		var t  = float(i) / 18.0
		var gy = H * 0.25 + t * (GY - H * 0.25)
		var a  = t * t * t * 0.22
		draw_rect(Rect2(0, gy, W, H * 0.06), Color(0.08, 0.04, 0.28, a), true)

	# Moon — static in sky
	var moon_x = W * 0.82
	var moon_y = H * 0.12
	draw_circle(Vector2(moon_x, moon_y), 26.0, Color(0.08, 0.06, 0.20, 1.0))
	draw_circle(Vector2(moon_x, moon_y), 22.0, Color(0.72, 0.78, 0.95, 0.92))
	draw_circle(Vector2(moon_x + 7, moon_y - 4), 16.0, Color(0.08, 0.06, 0.20, 1.0))
	# Moon glow
	draw_circle(Vector2(moon_x, moon_y), 38.0, Color(0.55, 0.62, 1.0, 0.06))
	draw_circle(Vector2(moon_x, moon_y), 50.0, Color(0.40, 0.50, 1.0, 0.03))

	# Stars
	for st in stars:
		var sx = fmod(st["x"] + scroll_x * st["sp"], W + 4.0)
		if sx < 0: sx += W + 4.0
		var tw = 0.60 + 0.40 * sin(scroll_x * 0.003 + st["x"] * 0.73)
		draw_circle(Vector2(sx, st["y"]), st["r"], Color(0.75, 0.88, 1.0, st["b"] * tw))

	# Horizon atmospheric glow line
	for i in range(12):
		var t  = float(i) / 12.0
		var gy = GY - 70.0 + t * 70.0
		draw_rect(Rect2(0, gy, W, 6), Color(0.16, 0.32, 0.95, (1.0 - t) * 0.16), true)

	# Far city
	_draw_buildings(buildings_far, scroll_x * 0.14, far_total_w,
		Color(0.03, 0.025, 0.18, 1.0), Color(0.0, 0.0, 0.0, 0.0))

	# Near city
	_draw_buildings(buildings_near, scroll_x * 0.38, near_total_w,
		Color(0.03, 0.022, 0.13, 1.0), Color(0.10, 0.24, 0.58, 0.38))

	# Ground — dark panel with neon edge
	draw_rect(Rect2(0, GY, W, H - GY), Color(0.01, 0.01, 0.07, 1.0), true)

	# Perspective grid — NO symmetry seam
	_draw_grid_perspective()

	# Ground strip neon lines
	draw_rect(Rect2(0, GY - 3, W, 6), Color(0.28, 0.60, 1.00, 1.0), true)
	draw_rect(Rect2(0, GY + 3, W, 3), Color(0.18, 0.42, 0.88, 0.65), true)
	draw_rect(Rect2(0, GY - 9, W, 5), Color(0.55, 0.80, 1.00, 0.22), true)

	# Accent glows on ground
	_draw_accent_lights()

func _draw_buildings(buildings: Array, offset: float, total_w: float,
		fill: Color, win_col: Color):
	if total_w <= 0: return
	for b in buildings:
		var bx = fmod(b["x"] - offset + total_w * 4.0, total_w)
		var by = GY - b["h"]
		draw_rect(Rect2(bx, by, b["w"], b["h"]), fill, true)
		if win_col.a > 0.05 and b["w"] > 22 and b["h"] > 35 and b.has("win_seed"):
			var seed = b["win_seed"]
			var cols = max(1, int(b["w"] / 14))
			var rows = max(1, int(b["h"] / 18))
			for r in range(rows):
				for c in range(cols):
					var idx = (seed ^ (r * 97 + c * 31)) & 0xFF
					if idx > 105: continue
					var wx = bx + 4.0 + c * 14.0
					var wy = by + 6.0 + r * 18.0
					if wx + 5 > bx + b["w"] - 3: continue
					if wy + 7 > by + b["h"] - 4: continue
					var flicker = 0.52 + 0.48 * sin(scroll_x * 0.005 + wx * 0.11 + wy * 0.17)
					draw_rect(Rect2(wx, wy, 5, 7),
						Color(win_col.r, win_col.g, win_col.b, win_col.a * flicker), true)

func _draw_grid_perspective():
	# True perspective grid — all vertical lines converge to a single vanishing point
	# This eliminates any symmetry seams because the tile offset is continuous
	var vp_x  = W * 0.50    # vanishing point X — centre of screen
	var vp_y  = GY - 46.0   # vanishing point Y — just above ground
	var gc    = Color(0.18, 0.40, 0.90, 1.0)

	# Number of perspective rays (vertical "lines")
	var ray_count  = 18
	var half_w     = W * 0.72   # half-spread of rays at ground level
	# Tile-scroll offset for the rays so they move with the world
	var tile_w     = W / float(ray_count - 1)
	var raw_off    = fmod(scroll_x * 0.50, tile_w)

	for i in range(ray_count + 2):
		var gx = (float(i) - 1.0) * tile_w - raw_off
		# Alpha fade toward edges
		var edge_t = abs((gx / W) - 0.5) * 2.0
		var a      = lerp(0.22, 0.04, edge_t * edge_t)
		draw_line(Vector2(vp_x, vp_y), Vector2(gx, GY),
				  Color(gc.r, gc.g, gc.b, a), 1.0)

	# Horizontal bands — perspective spacing (denser near ground)
	for i in range(9):
		var t  = float(i) / 8.0
		var yy = lerp(vp_y, GY, t * t)
		var a  = lerp(0.05, 0.28, t)
		draw_line(Vector2(0, yy), Vector2(W, yy), Color(gc.r, gc.g, gc.b, a), 1.0)

func _draw_accent_lights():
	for i in range(accent_lights.size()):
		var al  = accent_lights[i]
		var ax  = fmod(al["x_phase"] * W + scroll_x * 0.05, W)
		var ay  = GY + 8.0
		var flk = 0.60 + 0.40 * sin(scroll_x * 0.018 + al["flicker_phase"])
		var c   = al["col"]
		draw_circle(Vector2(ax, ay), 18.0, Color(c.r, c.g, c.b, 0.06 * flk))
		draw_circle(Vector2(ax, ay),  8.0, Color(c.r, c.g, c.b, 0.12 * flk))
		draw_circle(Vector2(ax, ay),  3.0, Color(c.r, c.g, c.b, 0.55 * flk))
