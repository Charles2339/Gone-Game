extends Area2D
class_name Coin

signal coin_collected

var speed     : float = 0.0
var anim_t    : float = 0.0
var collected : bool  = false
var fly_t     : float = -1.0

const RADIUS : float = 20.0
const SIDES  : int   = 6

func setup(p_speed: float):
	speed = p_speed

func _process(delta):
	anim_t += delta

	if fly_t >= 0.0:
		fly_t += delta
		position.y -= 130.0 * delta
		modulate.a  = max(0.0, 1.0 - fly_t * 3.5)
		if fly_t > 0.38:
			queue_free()
		update()
		return

	position.x -= speed * delta
	if position.x < -220:
		queue_free()
	update()

func _on_Coin_body_entered(body):
	if collected: return
	if body is Player:
		collected = true
		fly_t = 0.0
		$CollisionShape2D.set_deferred("disabled", true)
		emit_signal("coin_collected")

func _draw():
	var pulse = 0.70 + 0.30 * sin(anim_t * 6.5)
	var spin  = anim_t * 3.8

	var c  = Color(1.00, 0.88, 0.12, pulse)
	var gc = Color(1.00, 0.88, 0.12, pulse * 0.22)
	var lc = Color(1.00, 1.00, 0.72, pulse * 0.88)
	var rc = Color(1.00, 0.70, 0.05, pulse * 0.75)

	# Outer glow rings
	draw_circle(Vector2.ZERO, RADIUS + 10, Color(gc.r, gc.g, gc.b, gc.a * 0.45))
	draw_circle(Vector2.ZERO, RADIUS + 5,  gc)

	# Body — hexagon
	var pts = PoolVector2Array()
	for i in range(SIDES):
		var angle = spin + float(i) / float(SIDES) * TAU - PI * 0.5
		pts.append(Vector2(cos(angle) * RADIUS, sin(angle) * RADIUS))
	draw_colored_polygon(pts, c)

	# Rim shading
	for i in range(SIDES):
		var a1 = spin + float(i)     / float(SIDES) * TAU - PI * 0.5
		var a2 = spin + float(i + 1) / float(SIDES) * TAU - PI * 0.5
		var shade = 0.5 + 0.5 * cos(a1 + PI * 0.25)
		draw_line(
			Vector2(cos(a1) * RADIUS, sin(a1) * RADIUS),
			Vector2(cos(a2) * RADIUS, sin(a2) * RADIUS),
			Color(rc.r + shade * 0.25, rc.g + shade * 0.15, rc.b, pulse),
			2.2
		)

	# Inner highlight hexagon
	var ipts = PoolVector2Array()
	for i in range(SIDES):
		var angle = spin + float(i) / float(SIDES) * TAU - PI * 0.5
		ipts.append(Vector2(cos(angle) * RADIUS * 0.52, sin(angle) * RADIUS * 0.52))
	draw_colored_polygon(ipts, lc)

	# Sparkle dots at corners (rotating)
	for i in range(SIDES):
		var angle = spin + float(i) / float(SIDES) * TAU - PI * 0.5
		var spos  = Vector2(cos(angle) * (RADIUS + 7), sin(angle) * (RADIUS + 7))
		var sa    = 0.4 + 0.6 * abs(sin(anim_t * 5.0 + float(i)))
		draw_circle(spos, 2.0, Color(1, 1, 0.8, sa * pulse))
