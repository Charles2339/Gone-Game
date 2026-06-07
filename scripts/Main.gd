extends Node2D

enum GameState { MENU, PLAYING, DEAD }

var state        : int   = GameState.MENU
var score        : float = 0.0
var coins        : int   = 0
var best_score   : int   = 0
var best_coins   : int   = 0
var tap_cooldown : float = 0.0

onready var player  = $Player
onready var spawner = $ObstacleSpawner
onready var bg      = $Background
onready var ui      = $UI

func _ready():
	var save = ConfigFile.new()
	if save.load("user://save.cfg") == OK:
		best_score = save.get_value("scores", "best_score", 0)
		best_coins = save.get_value("scores", "best_coins", 0)

	player.connect("died", self, "_on_player_died")
	spawner.visible = false
	player.visible  = false
	ui.show_menu()

func _process(delta):
	tap_cooldown = max(0.0, tap_cooldown - delta)

	if state == GameState.PLAYING:
		score += delta
		ui.update_hud(int(score * 10), coins)
		bg.set_speed(spawner.speed)
		player.game_speed = spawner.speed

func _input(event):
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.scancode == KEY_SPACE or event.scancode == KEY_ENTER:
			_handle_tap()

func _handle_tap():
	if tap_cooldown > 0: return
	match state:
		GameState.MENU: _start_game()
		GameState.DEAD: _start_game()

func _start_game():
	tap_cooldown = 0.45
	score  = 0.0
	coins  = 0
	state  = GameState.PLAYING

	player.position   = Vector2(220, 500)
	player.velocity   = Vector2.ZERO
	player.dead       = false
	player.state      = Player.State.RUN
	player.jumps_left = 2
	player.anim_t     = 0.0
	player.dj_flash   = 0.0
	player.rag_pieces = []
	player.game_speed = spawner.base_speed
	player.visible    = true
	player._set_collision_stand()

	for child in spawner.get_children():
		child.queue_free()
	spawner.score           = 0.0
	spawner.speed           = spawner.base_speed
	spawner.spawn_timer     = 1.6
	spawner.obstacle_ranges = []
	spawner.visible         = true

	ui.show_hud()

func _on_player_died():
	state = GameState.DEAD

	# Freeze remaining obstacles so ragdoll reads cleanly
	for child in spawner.get_children():
		if child is Obstacle:
			child.speed = 0.0

	spawner.visible = false

	var final_score = int(score * 10)
	var new_best    = false
	if final_score > best_score:
		best_score = final_score
		new_best   = true
	if coins > best_coins:
		best_coins = coins

	var save = ConfigFile.new()
	save.set_value("scores", "best_score", best_score)
	save.set_value("scores", "best_coins", best_coins)
	save.save("user://save.cfg")

	ui.show_gameover(final_score, coins, best_score, best_coins, new_best)

func _on_coin_collected():
	coins += 1
