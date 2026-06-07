extends Node2D

# Draws the neon-grid sci-fi background: dark sky + stars + perspective grid.

var scroll_x : float = 0.0
var speed    : float = 480.0
var stars    : Array = []
var W        : float = 1280.0
var H        : float = 720.0

func _ready():
	randomize()
	for _i in range(120):
		stars.append({
			"x": randf() * W,
			"y": randf() * H * 0.65,
			"r": 0.8 + randf() * 1.6,
			"b": 0.4 + randf() * 0.6
		})

func set_speed(s: float):
	speed = s

func _process(delta):
	scroll_x += speed * delta
	update()

func _draw():
	# sky
	draw_rect(Rect2(0, 0, W, H), Color(0.03, 0.03, 0.10, 1.0), true)

	# stars
	for st in stars:
		var sx = fmod(st.x + scroll_x * 0.12, W)
		draw_circle(Vector2(sx, st.y), st.r,
		            Color(0.7, 0.85, 1.0, st.b))

	# horizon gradient (manual rects)
	for i in range(12):
		var t = float(i) / 12.0
		var a = lerp(0.0, 0.22, t)
		var y = H * 0.55 + t * H * 0.10
		draw_rect(Rect2(0, y, W, H * 0.10 / 12.0),
		          Color(0.1, 0.3, 0.8, a), true)

	# perspective grid
	_draw_grid()

	# ground line
	draw_rect(Rect2(0, H * 0.80, W, 3), Color(0.3, 0.6, 1.0, 0.9), true)

func _draw_grid():
	var horizon_y = H * 0.60
	var ground_y  = H * 0.80
	var col       = Color(0.2, 0.45, 0.9, 0.35)
	var vp_x      = W * 0.5   # vanishing point X

	# vertical lines — perspective lines to vanishing point
	var num_v = 14
	for i in range(num_v + 1):
		var gx = float(i) / float(num_v) * W
		# scroll offset
		var offset = fmod(scroll_x * 0.5, W / float(num_v))
		var gx2 = fmod(gx - offset + W, W)
		draw_line(Vector2(gx2, ground_y), Vector2(vp_x, horizon_y), col, 1.2)

	# horizontal lines
	var num_h = 7
	for i in range(num_h + 1):
		var t = float(i) / float(num_h)
		var gy = lerp(horizon_y, ground_y, t)
		draw_line(Vector2(0, gy), Vector2(W, gy), col, 1.0)
