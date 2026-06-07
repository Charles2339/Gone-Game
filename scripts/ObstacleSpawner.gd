extends Node2D

export var ground_y   : float = 580.0
export var spawn_x    : float = 1420.0
export var base_speed : float = 480.0

var obstacle_scene : PackedScene
var coin_scene     : PackedScene
var speed          : float = 480.0
var score          : float = 0.0

var spawn_timer    : float = 1.6
var min_gap_time   : float = 1.85

# Track obstacle world-x ranges so coins never spawn inside them
var obstacle_ranges : Array = []

func _ready():
	obstacle_scene = preload("res://scenes/Obstacle.tscn")
	coin_scene     = preload("res://scenes/Coin.tscn")
	speed = base_speed
	randomize()

func _process(delta):
	score += delta
	speed = min(base_speed + score * 15.0, 860.0)
	min_gap_time = max(1.10, 1.90 - score * 0.013)

	# Slide obstacle x-ranges with the world
	var i = obstacle_ranges.size() - 1
	while i >= 0:
		obstacle_ranges[i]["xl"] -= speed * delta
		obstacle_ranges[i]["xr"] -= speed * delta
		if obstacle_ranges[i]["xr"] < -100:
			obstacle_ranges.remove(i)
		i -= 1

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = min_gap_time + randf() * 0.45
		_pick_wave()

func _pick_wave():
	var roll = randf()
	if roll < 0.48:
		_spawn_single()
	elif roll < 0.70:
		_spawn_obs_then_coins()
	elif roll < 0.86:
		_spawn_coin_arc()
	else:
		# Two obstacles with a mandatory safe gap between them
		_spawn_single()
		var t = Timer.new()
		add_child(t)
		t.wait_time = 1.05 + randf() * 0.55
		t.one_shot  = true
		t.connect("timeout", self, "_on_gap_timer", [t])
		t.start()

func _on_gap_timer(t: Timer):
	t.queue_free()
	_spawn_single()

func _build_params() -> Dictionary:
	var roll  = randf()
	var phase = clamp(score / 45.0, 0.0, 1.0)
	var kind  : String
	var w     : float
	var h     : float
	var pos_y : float

	if roll < 0.33 + 0.08 * (1.0 - phase):
		kind  = "low"
		w     = 34.0 + randf() * 18.0
		h     = 46.0 + randf() * 28.0        # 46-74 px — climbable
		pos_y = ground_y - h * 0.5
	elif roll < 0.60:
		kind  = "med"
		w     = 36.0 + randf() * 16.0
		h     = 80.0 + randf() * 28.0        # 80-108 px — must jump
		pos_y = ground_y - h * 0.5
	elif roll < 0.78 + phase * 0.08:
		kind  = "tall"
		w     = 32.0 + randf() * 14.0
		h     = 114.0 + randf() * 28.0       # 114-142 px — double jump
		pos_y = ground_y - h * 0.5
	else:
		kind  = "hang"
		w     = 60.0 + randf() * 35.0
		h     = 46.0 + randf() * 22.0
		# Bottom of obstacle must be above player-sliding head (~540)
		# Player head when sliding: position.y - 40 = 580-40 = 540
		# Leave 12px safety margin → bottom at 552 max
		# pos_y is CENTER, so pos_y = bottom - h/2
		var bottom = 530.0 + randf() * 18.0
		pos_y = bottom - h * 0.5

	return {"kind": kind, "w": w, "h": h, "pos_y": pos_y}

func _spawn_single():
	var p = _build_params()
	_create_obstacle(p.kind, p.w, p.h, p.pos_y)

func _spawn_obs_then_coins():
	var p = _build_params()
	_create_obstacle(p.kind, p.w, p.h, p.pos_y)
	if p.kind == "hang": return
	# Coins arc over the obstacle
	var coin_y   = p.pos_y - p.h * 0.5 - 52.0
	coin_y       = max(coin_y, 170.0)
	var count    = 3 + randi() % 3
	var gap      = 54.0
	var start_cx = spawn_x + p.w * 0.5 + 30.0
	for i in range(count):
		var cx = start_cx + i * gap
		var cy = coin_y - sin(float(i) / float(count - 1) * PI) * 30.0
		_try_coin(cx, cy)

func _spawn_coin_arc():
	var count  = 4 + randi() % 4
	var arc_h  = 70.0 + randf() * 100.0
	var base_y = ground_y - 100.0
	var gap    = 52.0
	for i in range(count):
		var t  = float(i) / float(max(count - 1, 1))
		var cx = spawn_x + i * gap
		var cy = base_y - arc_h * sin(t * PI)
		_try_coin(cx, cy)

func _create_obstacle(kind: String, w: float, h: float, pos_y: float):
	var obs = obstacle_scene.instance()
	add_child(obs)
	obs.setup(speed, kind, w, h)
	obs.position = Vector2(spawn_x, pos_y)
	# Register range with padding so coins don't land on/inside it
	obstacle_ranges.append({
		"xl": spawn_x - w * 0.5 - 24.0,
		"xr": spawn_x + w * 0.5 + 24.0,
		"ty": pos_y - h * 0.5
	})

func _try_coin(cx: float, cy: float):
	for r in obstacle_ranges:
		if cx >= r["xl"] and cx <= r["xr"] and cy >= r["ty"] - 18.0:
			return
	var coin = coin_scene.instance()
	add_child(coin)
	coin.setup(speed)
	coin.position = Vector2(cx, cy)
	coin.connect("coin_collected", get_parent(), "_on_coin_collected")
