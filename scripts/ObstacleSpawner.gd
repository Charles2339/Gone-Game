extends Node2D

export var ground_y   : float = 580.0
export var spawn_x    : float = 1420.0
export var base_speed : float = 480.0

var obstacle_scene : PackedScene
var coin_scene     : PackedScene
var speed          : float = 480.0
var score          : float = 0.0

var spawn_timer    : float = 1.8
# Minimum time between any two obstacle groups
var min_gap_time   : float = 1.90

# Track obstacle world-x ranges so coins never spawn inside them
# Also used to enforce minimum spacing between obstacles
var obstacle_ranges : Array = []

# Cooldown after a pair wave so we never triple-stack
var wave_cooldown : float = 0.0

func _ready():
	obstacle_scene = preload("res://scenes/Obstacle.tscn")
	coin_scene     = preload("res://scenes/Coin.tscn")
	speed          = base_speed
	randomize()

func _process(delta):
	score        += delta
	speed         = min(base_speed + score * 14.0, 840.0)
	min_gap_time  = max(1.10, 1.95 - score * 0.012)
	wave_cooldown = max(0.0, wave_cooldown - delta)

	# Slide obstacle x-ranges with the world
	var i = obstacle_ranges.size() - 1
	while i >= 0:
		obstacle_ranges[i]["xl"] -= speed * delta
		obstacle_ranges[i]["xr"] -= speed * delta
		if obstacle_ranges[i]["xr"] < -150:
			obstacle_ranges.remove(i)
		i -= 1

	spawn_timer -= delta
	if spawn_timer <= 0.0 and wave_cooldown <= 0.0:
		spawn_timer = min_gap_time + randf() * 0.50
		_pick_wave()

func _pick_wave():
	var roll  = randf()
	var phase = clamp(score / 50.0, 0.0, 1.0)

	if roll < 0.40:
		# Single obstacle
		_spawn_single()
	elif roll < 0.60:
		# Obstacle then coins arcing over it
		_spawn_obs_then_coins()
	elif roll < 0.75:
		# Pure coin arc at run height or jump height
		_spawn_coin_arc()
	elif roll < 0.88 + phase * 0.05:
		# Two obstacles spaced far enough to never be on screen simultaneously stacked
		_spawn_pair()
	else:
		# Three coins in a line at chest height — easy pickup
		_spawn_coin_line()

func _spawn_pair():
	# Only spawn pair if score is high enough and use a large gap
	var gap_time = 1.15 + randf() * 0.55
	_spawn_single()
	wave_cooldown = gap_time + 0.30

	var t = Timer.new()
	add_child(t)
	t.wait_time  = gap_time
	t.one_shot   = true
	t.connect("timeout", self, "_on_pair_timer", [t])
	t.start()

func _on_pair_timer(t: Timer):
	t.queue_free()
	_spawn_single()

func _build_params() -> Dictionary:
	var roll  = randf()
	var phase = clamp(score / 50.0, 0.0, 1.0)
	var kind  : String
	var w     : float
	var h     : float
	var pos_y : float
	var otype : int = randi() % 3   # visual variant

	if roll < 0.32 + 0.06 * (1.0 - phase):
		kind  = "low"
		w     = 36.0 + randf() * 20.0
		h     = 48.0 + randf() * 26.0   # 48-74 px — climbable
		pos_y = ground_y - h * 0.5
	elif roll < 0.58:
		kind  = "med"
		w     = 38.0 + randf() * 18.0
		h     = 80.0 + randf() * 26.0   # 80-106 px — must jump
		pos_y = ground_y - h * 0.5
	elif roll < 0.78 + phase * 0.08:
		kind  = "tall"
		w     = 32.0 + randf() * 16.0
		h     = 112.0 + randf() * 30.0  # 112-142 px — double jump
		pos_y = ground_y - h * 0.5
	else:
		kind  = "hang"
		w     = 62.0 + randf() * 38.0
		h     = 46.0 + randf() * 20.0
		# Bottom must clear player slide height (ground_y - 40 = 540), 14px margin
		var bottom = 526.0 + randf() * 16.0
		pos_y = bottom - h * 0.5

	return {"kind": kind, "w": w, "h": h, "pos_y": pos_y, "otype": otype}

func _spawn_single():
	var p = _build_params()
	_create_obstacle(p.kind, p.w, p.h, p.pos_y, p.otype)

func _spawn_obs_then_coins():
	var p = _build_params()
	_create_obstacle(p.kind, p.w, p.h, p.pos_y, p.otype)
	if p.kind == "hang": return

	# Arc coins over the obstacle, safely above it
	var coin_y   = p.pos_y - p.h * 0.5 - 58.0
	coin_y       = max(coin_y, 160.0)
	var count    = 3 + randi() % 3
	var gap      = 56.0
	var start_cx = spawn_x + p.w * 0.5 + 36.0
	for i in range(count):
		var cx = start_cx + i * gap
		var cy = coin_y - sin(float(i) / float(count - 1) * PI) * 32.0
		_try_coin(cx, cy)

func _spawn_coin_arc():
	var count  = 5 + randi() % 4
	var arc_h  = 80.0 + randf() * 110.0
	var base_y = ground_y - 110.0
	var gap    = 54.0
	for i in range(count):
		var t  = float(i) / float(max(count - 1, 1))
		var cx = spawn_x + i * gap
		var cy = base_y - arc_h * sin(t * PI)
		_try_coin(cx, cy)

func _spawn_coin_line():
	# Horizontal row of coins at easy-pickup height
	var count  = 4 + randi() % 3
	var base_y = ground_y - 130.0
	var gap    = 52.0
	for i in range(count):
		_try_coin(spawn_x + i * gap, base_y)

func _create_obstacle(kind: String, w: float, h: float, pos_y: float, otype: int = 0):
	# Enforce minimum spacing: last registered obstacle must be off screen enough
	for r in obstacle_ranges:
		if r["xr"] > spawn_x - 220:
			# Too close to last obstacle — skip this spawn
			return

	var obs = obstacle_scene.instance()
	add_child(obs)
	obs.setup(speed, kind, w, h, otype)
	obs.position = Vector2(spawn_x, pos_y)
	# Register range with generous padding
	obstacle_ranges.append({
		"xl": spawn_x - w * 0.5 - 28.0,
		"xr": spawn_x + w * 0.5 + 28.0,
		"ty": pos_y - h * 0.5
	})

func _try_coin(cx: float, cy: float):
	# Don't place coins inside or directly atop any obstacle
	for r in obstacle_ranges:
		if cx >= r["xl"] and cx <= r["xr"] and cy >= r["ty"] - 22.0:
			return
	var coin = coin_scene.instance()
	add_child(coin)
	coin.setup(speed)
	coin.position = Vector2(cx, cy)
	coin.connect("coin_collected", get_parent(), "_on_coin_collected")
