extends CanvasLayer

onready var menu_screen    = $MenuScreen
onready var hud_screen     = $HUDScreen
onready var gameover_screen = $GameOverScreen

onready var hud_score  = $HUDScreen/ScoreLabel
onready var hud_coins  = $HUDScreen/CoinsLabel

onready var go_score   = $GameOverScreen/ScoreLabel
onready var go_coins   = $GameOverScreen/CoinsLabel
onready var go_best    = $GameOverScreen/BestLabel
onready var go_new     = $GameOverScreen/NewBestLabel

func show_menu():
	menu_screen.visible    = true
	hud_screen.visible     = false
	gameover_screen.visible = false

func show_hud():
	menu_screen.visible    = false
	hud_screen.visible     = true
	gameover_screen.visible = false

func show_gameover(score: int, coins: int, best: int, best_c: int, new_best: bool):
	hud_screen.visible     = false
	gameover_screen.visible = true
	go_score.text  = "Score  %d" % score
	go_coins.text  = "Coins  %d" % coins
	go_best.text   = "Best   %d" % best
	go_new.visible = new_best

func update_hud(score: int, coins: int):
	hud_score.text = "%d" % score
	hud_coins.text = "⬡ %d" % coins
