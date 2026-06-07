extends StaticBody2D
class_name Obstacle

var speed    : float = 0.0
var w        : float = 40.0
var h        : float = 60.0
var kind     : String = "low"
var obs_type : int   = 0   # visual variant 0-2

const C_LOW  = Color(1.00, 0.28, 0.28, 1.0)
const C_MED  = Color(1.00, 0.58, 0.12, 1.0)
const C_TALL = Color(0.85, 0.20, 0.90, 1.0)
const C_HANG = Color(0.20, 0.72, 1.00, 1.0)

var draw_col : Color = C_LOW
var anim_t   : float = 0.0

func _ready():
	add_to_group("obstacles")

func setup(p_speed: float, p_kind: String, p_w: float, p_h: float, p_type: int = 0):
	speed    = p_speed
	kind     = p_kind
	w        = p_w
	h        = p_h
	obs_type = p_type
	var shape = $CollisionShape2D.shape as RectangleShape2D
	shape.extents = Vector2(w * 0.5, h * 0.5)
	match kind:
		"low":  draw_col = C_LOW
		"med":  draw_col = C_MED
		"tall": draw_col = C_TALL
		"hang": draw_col = C_HANG

func _process(delta):
	anim_t     += delta
	position.x -= speed * delta
	if position.x < -260:
		queue_free()
	update()

func _draw():
	var c  = draw_col
	var gc = Color(c.r, c.g, c.b, 0.10)

	# Outer ambient glow
	draw_rect(Rect2(-w*0.5 - 9, -h*0.5 - 9, w + 18, h + 18),
			  Color(c.r, c.g, c.b, 0.05), true)
	draw_rect(Rect2(-w*0.5 - 4, -h*0.5 - 4, w + 8,  h + 8),
			  Color(c.r, c.g, c.b, 0.10), true)

	# Main fill — dark tinted
	draw_rect(Rect2(-w*0.5, -h*0.5, w, h),
			  Color(c.r*0.18, c.g*0.18, c.b*0.22, 0.92), true)

	# Visual variant
	match obs_type:
		0: _draw_stripes(c)
		1: _draw_circuit(c)
		2: _draw_dots(c)

	# Border — glowing neon edge
	draw_rect(Rect2(-w*0.5, -h*0.5, w, h), c, false, 2.8)

	# Top neon highlight line
	draw_line(Vector2(-w*0.5 + 2, -h*0.5),
			  Vector2( w*0.5 - 2, -h*0.5),
			  Color(1.0, 1.0, 1.0, 0.60), 2.0)

	# Corner bracket marks
	var cm = min(w, h) * 0.15
	var br = Color(c.r, c.g, c.b, 0.80)
	draw_line(Vector2(-w*0.5,      -h*0.5), Vector2(-w*0.5 + cm, -h*0.5), br, 2.2)
	draw_line(Vector2(-w*0.5,      -h*0.5), Vector2(-w*0.5,      -h*0.5 + cm), br, 2.2)
	draw_line(Vector2( w*0.5,      -h*0.5), Vector2( w*0.5 - cm, -h*0.5), br, 2.2)
	draw_line(Vector2( w*0.5,      -h*0.5), Vector2( w*0.5,      -h*0.5 + cm), br, 2.2)
	draw_line(Vector2(-w*0.5,       h*0.5), Vector2(-w*0.5 + cm,  h*0.5), br, 2.2)
	draw_line(Vector2(-w*0.5,       h*0.5), Vector2(-w*0.5,       h*0.5 - cm), br, 2.2)
	draw_line(Vector2( w*0.5,       h*0.5), Vector2( w*0.5 - cm,  h*0.5), br, 2.2)
	draw_line(Vector2( w*0.5,       h*0.5), Vector2( w*0.5,       h*0.5 - cm), br, 2.2)

	# Pulsing glow on border (subtle)
	var pulse = 0.55 + 0.45 * sin(anim_t * 3.5)
	draw_rect(Rect2(-w*0.5, -h*0.5, w, h),
			  Color(c.r, c.g, c.b, 0.08 * pulse), false, 5.0)

	# Hanging obstacle — danger spikes below
	if kind == "hang":
		var ns  = max(2, int(w / 20.0))
		var sw2 = w / ns
		for i in range(ns):
			var sx = -w*0.5 + sw2 * (float(i) + 0.5)
			var spike_pts = PoolVector2Array([
				Vector2(sx - 6, h*0.5),
				Vector2(sx,     h*0.5 + 24),
				Vector2(sx + 6, h*0.5)
			])
			draw_colored_polygon(spike_pts, Color(c.r, c.g, c.b, 0.85))
			draw_line(Vector2(sx - 6, h*0.5), Vector2(sx, h*0.5 + 24), c, 1.5)
			draw_line(Vector2(sx + 6, h*0.5), Vector2(sx, h*0.5 + 24), c, 1.5)

func _draw_stripes(c: Color):
	# Diagonal warning stripes
	var sw  = 18.0
	var num = int((w + h) / sw) + 3
	for i in range(num):
		var x0  = -w*0.5 + i * sw - h
		var x1  = x0 + h
		var ax  = clamp(x0, -w*0.5, w*0.5)
		var bx  = clamp(x1, -w*0.5, w*0.5)
		if ax >= bx: continue
		var ay_off = (ax - x0) / h
		var by_off = (bx - x0) / h
		draw_line(
			Vector2(ax, -h*0.5 + h * ay_off),
			Vector2(bx, -h*0.5 + h * by_off),
			Color(c.r, c.g, c.b, 0.20), 3.0)

func _draw_circuit(c: Color):
	# Circuit-board-like horizontal lines and dots
	var steps = max(2, int(h / 18.0))
	for i in range(1, steps):
		var ly = -h*0.5 + float(i) / float(steps) * h
		var alpha = 0.15 + 0.08 * sin(anim_t * 4.0 + float(i))
		draw_line(Vector2(-w*0.5 + 4, ly), Vector2(w*0.5 - 4, ly),
				  Color(c.r, c.g, c.b, alpha), 1.2)
	# Dot nodes
	var dot_count = max(1, int(w / 22.0))
	for i in range(dot_count):
		var dx = -w*0.5 + (float(i) + 0.5) / float(dot_count) * w
		var dy = 0.0
		var da = 0.40 + 0.35 * sin(anim_t * 5.5 + float(i) * 1.3)
		draw_circle(Vector2(dx, dy), 3.5, Color(c.r, c.g, c.b, da))

func _draw_dots(c: Color):
	# Grid of glowing dots
	var cols = max(2, int(w / 18.0))
	var rows = max(2, int(h / 18.0))
	for r in range(rows):
		for col_i in range(cols):
			var dx = -w*0.5 + (float(col_i) + 0.5) / float(cols) * w
			var dy = -h*0.5 + (float(r)     + 0.5) / float(rows) * h
			var da = 0.25 + 0.20 * sin(anim_t * 4.0 + float(r*cols + col_i) * 0.8)
			draw_circle(Vector2(dx, dy), 2.2, Color(c.r, c.g, c.b, da))
