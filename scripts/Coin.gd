extends Area2D
class_name Coin

signal coin_collected

var speed     : float = 0.0
var anim_t    : float = 0.0
var collected : bool  = false
var fly_t     : float = -1.0

const RADIUS : float = 16.0
const SIDES  : int   = 6

# Bobbing — base_y is set the first time _process runs,
# AFTER the spawner has placed coin.position
const BOB_AMP  : float = 5.0
const BOB_FREQ : float = 3.2
var bob_phase  : float = 0.0
var base_y     : float = -99999.0   # sentinel — unset

func setup(p_speed: float):
	speed     = p_speed
	bob_phase = randf() * TAU
	base_y    = -99999.0   # will be latched in first _process frame

func _process(delta):
	anim_t += delta

	if fly_t >= 0.0:
		fly_t      += delta
		position.y -= 160.0 * delta
		modulate.a  = max(0.0, 1.0 - fly_t * 3.2)
		if fly_t > 0.40:
			queue_free()
		update()
		return

	# Latch base_y once position has been placed by the spawner
	if base_y < -9000.0:
		base_y = position.y

	position.x -= speed * delta
	position.y  = base_y + sin(anim_t * BOB_FREQ + bob_phase) * BOB_AMP
	if position.x < -260:
		queue_free()
	update()

func _on_Coin_body_entered(body):
	if collected: return
	if body is Player:
		collected = true
		fly_t     = 0.0
		$CollisionShape2D.set_deferred("disabled", true)
		emit_signal("coin_collected")

func _draw():
	var pulse = 0.72 + 0.28 * sin(anim_t * 7.0)
	var spin  = anim_t * 3.6

	var c  = Color(1.00, 0.88, 0.12, pulse)
	var gc = Color(1.00, 0.88, 0.12, pulse * 0.18)
	var lc = Color(1.00, 1.00, 0.75, pulse * 0.90)
	var rc = Color(1.00, 0.68, 0.05, pulse * 0.80)

	# Outer soft glow
	draw_circle(Vector2.ZERO, RADIUS + 14, Color(gc.r, gc.g, gc.b, gc.a * 0.35))
	draw_circle(Vector2.ZERO, RADIUS + 7,  Color(gc.r, gc.g, gc.b, gc.a * 0.65))

	# Coin body (hexagon)
	var pts = PoolVector2Array()
	for i in range(SIDES):
		var angle = spin + float(i) / float(SIDES) * TAU - PI * 0.5
		pts.append(Vector2(cos(angle) * RADIUS, sin(angle) * RADIUS))
	draw_colored_polygon(pts, c)

	# Rim shading
	for i in range(SIDES):
		var a1    = spin + float(i)     / float(SIDES) * TAU - PI * 0.5
		var a2    = spin + float(i + 1) / float(SIDES) * TAU - PI * 0.5
		var shade = 0.5 + 0.5 * cos(a1 + PI * 0.25)
		draw_line(
			Vector2(cos(a1) * RADIUS, sin(a1) * RADIUS),
			Vector2(cos(a2) * RADIUS, sin(a2) * RADIUS),
			Color(rc.r + shade * 0.25, rc.g + shade * 0.15, rc.b, pulse), 2.5)

	# Inner highlight
	var ipts = PoolVector2Array()
	for i in range(SIDES):
		var angle = spin + float(i) / float(SIDES) * TAU - PI * 0.5
		ipts.append(Vector2(cos(angle) * RADIUS * 0.50, sin(angle) * RADIUS * 0.50))
	draw_colored_polygon(ipts, lc)

	# Sparkle dots at tips
	for i in range(SIDES):
		var angle = spin + float(i) / float(SIDES) * TAU - PI * 0.5
		var spos  = Vector2(cos(angle) * (RADIUS + 8), sin(angle) * (RADIUS + 8))
		var sa    = 0.35 + 0.65 * abs(sin(anim_t * 5.5 + float(i)))
		draw_circle(spos, 2.2, Color(1.0, 1.0, 0.85, sa * pulse))
