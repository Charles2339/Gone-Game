extends Area2D
class_name Coin

var speed     : float = 0.0
var radius    : float = 12.0
var anim_t    : float = 0.0
var collected : bool  = false

signal coin_collected

func setup(p_speed: float):
	speed = p_speed

func _physics_process(delta):
	position.x -= speed * delta
	anim_t += delta
	if position.x < -200:
		queue_free()

func _on_Coin_body_entered(body):
	if collected: return
	if body is Player:
		collected = true
		emit_signal("coin_collected")
		queue_free()

func _draw():
	var pulse = 0.7 + 0.3 * sin(anim_t * 5.0)
	var c = Color(1.0, 0.85, 0.1, pulse)
	var gc = Color(1.0, 0.85, 0.1, pulse * 0.3)
	draw_circle(Vector2.ZERO, radius + 5, gc)
	draw_circle(Vector2.ZERO, radius, c)
	draw_circle(Vector2.ZERO, radius * 0.55, Color(1, 1, 0.6, pulse * 0.7))
	update()
