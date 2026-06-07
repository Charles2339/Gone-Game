extends CanvasLayer

onready var menu_screen     = $MenuScreen
onready var hud_screen      = $HUDScreen
onready var gameover_screen = $GameOverScreen

onready var hud_score = $HUDScreen/ScoreLabel
onready var hud_coins = $HUDScreen/CoinsLabel

onready var go_score  = $GameOverScreen/ScoreLabel
onready var go_coins  = $GameOverScreen/CoinsLabel
onready var go_best   = $GameOverScreen/BestLabel
onready var go_new    = $GameOverScreen/NewBestLabel

var go_anim_t    : float = -1.0
var score_shown  : int   = 0
var target_score : int   = 0

func _process(delta):
	if gameover_screen.visible and go_anim_t >= 0.0:
		go_anim_t += delta
		if score_shown < target_score:
			score_shown = min(target_score, score_shown + max(1, int(target_score * delta * 2.2)))
			go_score.text = "Score   %d" % score_shown

func show_menu():
	menu_screen.visible     = true
	hud_screen.visible      = false
	gameover_screen.visible = false

func show_hud():
	menu_screen.visible     = false
	hud_screen.visible      = true
	gameover_screen.visible = false

func show_gameover(score: int, coins: int, best: int, best_c: int, new_best: bool):
	hud_screen.visible      = false
	gameover_screen.visible = true
	go_anim_t    = 0.0
	score_shown  = 0
	target_score = score
	go_score.text  = "Score   0"
	go_coins.text  = "Coins   %d" % coins
	go_best.text   = "Best    %d" % best
	go_new.visible = new_best

func update_hud(score: int, coins: int):
	hud_score.text = "%d" % score
	hud_coins.text = "◆  %d" % coins
