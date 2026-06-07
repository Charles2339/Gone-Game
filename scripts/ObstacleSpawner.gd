extends Node2D

export var ground_y   : float = 580.0
export var spawn_x    : float = 1400.0
export var base_speed : float = 480.0

var obstacle_scene : PackedScene
var coin_scene     : PackedScene
var spawn_timer    : float = 0.0
var spawn_interval : float = 2.2
var speed          : float = 480.0
var score          : float = 0.0

func _ready():
	obstacle_scene = preload("res://scenes/Obstacle.tscn")
	coin_scene     = preload("res://scenes/Coin.tscn")
	speed = base_speed
	randomize()

func _process(delta):
	score += delta
	# gradually increase speed
	speed = base_speed + score * 18.0
	speed = min(speed, 900.0)
	# gradually decrease interval
	spawn_interval = max(0.95, 2.2 - score * 0.025)

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = spawn_interval + randf() * 0.4
		_spawn_wave()

func _spawn_wave():
	var roll = randf()
	if roll < 0.55:
		_spawn_obstacle()
	elif roll < 0.80:
		_spawn_obstacle()
		_spawn_coin_row()
	else:
		_spawn_coin_row()

func _spawn_obstacle():
	var obs = obstacle_scene.instance()
	add_child(obs)
	var kind_roll = randf()
	var kind  : String
	var w     : float
	var h     : float
	var pos_y : float

	if kind_roll < 0.40:
		# short ground obstacle — must jump over
		kind  = "low"
		w     = 38.0
		h     = 55.0 + randf() * 35.0
		pos_y = ground_y - h * 0.5
	elif kind_roll < 0.70:
		# tall ground obstacle — must slide under... add a gap
		kind  = "high"
		w     = 42.0
		h     = 110.0 + randf() * 30.0
		pos_y = ground_y - h * 0.5
	else:
		# hanging top obstacle — duck/slide under
		kind  = "top"
		w     = 50.0
		h     = 65.0
		pos_y = ground_y - 140.0 - h * 0.5   # hanging from above

	obs.setup(speed, kind, w, h)
	obs.position = Vector2(spawn_x, pos_y)

func _spawn_coin_row():
	var count = 3 + randi() % 4
	var gap   = 48.0
	var start_x = spawn_x
	var y = ground_y - 90.0 - randf() * 60.0

	for i in range(count):
		var coin = coin_scene.instance()
		add_child(coin)
		coin.setup(speed)
		coin.position = Vector2(start_x + i * gap, y)
		coin.connect("coin_collected", get_parent(), "_on_coin_collected")
