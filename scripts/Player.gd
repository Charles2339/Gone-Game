extends KinematicBody2D
class_name Player

signal died

const GRAVITY        = 2400.0
const JUMP_FORCE     = -960.0
const JUMP2_FORCE    = -820.0
const SLIDE_DURATION = 0.52
const CLIMB_DURATION = 0.30
const CLIMB_VY       = -500.0

const STAND_H  = 88.0
const SLIDE_H  = 40.0
const RUN_CYCLE = 0.28

enum State { RUN, JUMP, DOUBLE_JUMP, SLIDE, CLIMB, DEAD }

var state       : int   = State.RUN
var velocity    : Vector2 = Vector2.ZERO
var jumps_left  : int   = 2
var slide_timer : float = 0.0
var climb_timer : float = 0.0
var anim_t      : float = 0.0
var dead        : bool  = false
var game_speed  : float = 480.0

var dj_flash    : float = 0.0

var rag_pieces  : Array = []
const RAG_GRAVITY = 1100.0

var touch_start_y : float = -1.0
const SWIPE_DOWN  = 40.0

onready var col_stand : CollisionShape2D = $CollisionStand
onready var col_slide : CollisionShape2D = $CollisionSlide

func _ready():
	_set_collision_stand()

func _input(event):
	if dead: return
	if state == State.CLIMB: return
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start_y = event.position.y
		else:
			if touch_start_y >= 0:
				var dy = event.position.y - touch_start_y
				if dy > SWIPE_DOWN:
					_try_slide()
				else:
					_try_jump()
				touch_start_y = -1.0
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.scancode:
			KEY_SPACE, KEY_UP: _try_jump()
			KEY_DOWN, KEY_S:   _try_slide()

func _try_jump():
	if state == State.SLIDE: return
	if jumps_left > 0:
		jumps_left -= 1
		velocity.y = JUMP_FORCE if jumps_left == 1 else JUMP2_FORCE
		state = State.JUMP if jumps_left == 1 else State.DOUBLE_JUMP
		if state == State.DOUBLE_JUMP:
			dj_flash = 0.20
		anim_t = 0.0

func _try_slide():
	if is_on_floor() and state != State.SLIDE:
		state = State.SLIDE
		slide_timer = SLIDE_DURATION
		velocity.y = 60.0
		_set_collision_slide()

func start_climb(obs_h: float):
	if dead or state == State.SLIDE or state == State.CLIMB: return
	state = State.CLIMB
	climb_timer = CLIMB_DURATION
	var boost = clamp(obs_h * 8.0 + 380.0, 500.0, 780.0)
	velocity.y = -boost
	anim_t = 0.0

func _physics_process(delta):
	if dead:
		_update_ragdoll(delta)
		update()
		return

	dj_flash = max(0.0, dj_flash - delta)

	if state == State.CLIMB:
		velocity.y += GRAVITY * 0.28 * delta
		climb_timer -= delta
		if climb_timer <= 0.0:
			state = State.JUMP
			jumps_left = max(jumps_left, 1)
	else:
		velocity.y += GRAVITY * delta

	if state == State.SLIDE:
		slide_timer -= delta
		if slide_timer <= 0.0:
			_set_collision_stand()
			state = State.RUN if is_on_floor() else State.JUMP

	velocity = move_and_slide(velocity, Vector2.UP)

	for i in range(get_slide_count()):
		var coll = get_slide_collision(i)
		if coll.collider.is_in_group("obstacles"):
			_handle_obstacle_collision(coll)

	if is_on_floor():
		if state != State.SLIDE and state != State.CLIMB:
			if state == State.JUMP or state == State.DOUBLE_JUMP:
				anim_t = 0.0
			state = State.RUN
		jumps_left = 2
		velocity.y = 0.0

	if state == State.RUN:
		anim_t += delta
	elif state != State.DEAD:
		anim_t += delta

	update()

func _handle_obstacle_collision(coll):
	if dead: return
	var normal = coll.normal
	var obs    = coll.collider

	if normal.y < -0.55:
		# Landed on top
		if state == State.JUMP or state == State.DOUBLE_JUMP:
			anim_t = 0.0
		if state != State.SLIDE and state != State.CLIMB:
			state = State.RUN
		jumps_left = 2
		velocity.y = 0.0
	elif normal.y > 0.55:
		# Hit bottom of hanging obstacle
		if state != State.SLIDE:
			die()
		else:
			velocity.y = max(velocity.y, 0.0)
	elif abs(normal.x) > 0.35:
		# Side collision
		if state == State.CLIMB: return
		if obs.kind == "low" and game_speed < 640.0 and obs.h < 82.0:
			start_climb(obs.h)
		else:
			die()

func _set_collision_stand():
	col_stand.disabled = false
	col_slide.disabled = true

func _set_collision_slide():
	col_stand.disabled = true
	col_slide.disabled = false

func die():
	if dead: return
	dead = true
	state = State.DEAD
	_spawn_ragdoll()
	emit_signal("died")

func _spawn_ragdoll():
	rag_pieces.clear()
	var neon = Color(0.42, 0.82, 1.0, 1.0)
	var red  = Color(1.0, 0.35, 0.35, 1.0)
	var bvx  = -80.0 - randf() * 60.0
	var bvy  = -250.0 - randf() * 120.0

	rag_pieces.append({
		"type": "c", "pos": Vector2(3, -82), "r": 13.0, "col": neon.duplicate(),
		"vel": Vector2(bvx + randf()*50-25, bvy - 100 - randf()*80),
		"rot": 0.0, "rv": randf()*7-3.5
	})
	rag_pieces.append({
		"type": "l", "pos": Vector2(0, -54), "len": 28.0, "col": neon.duplicate(),
		"vel": Vector2(bvx, bvy + randf()*40),
		"rot": 0.2, "rv": randf()*5-2.5
	})
	for sx in [1, -1]:
		rag_pieces.append({
			"type": "l", "pos": Vector2(sx*7, -64), "len": 22.0, "col": neon.duplicate(),
			"vel": Vector2(bvx + sx * 180 + randf()*60, bvy - randf()*80),
			"rot": float(sx) * 1.4, "rv": float(sx) * (randf()*10+5)
		})
	for sx in [1, -1]:
		rag_pieces.append({
			"type": "l", "pos": Vector2(sx*6, -20), "len": 25.0, "col": red.duplicate(),
			"vel": Vector2(bvx + sx*120 + randf()*50, bvy + 80 + randf()*80),
			"rot": float(sx) * 0.8, "rv": float(-sx) * (randf()*9+4)
		})

func _update_ragdoll(delta):
	for p in rag_pieces:
		p["vel"].y += RAG_GRAVITY * delta
		p["pos"] += p["vel"] * delta
		p["rot"] += p["rv"] * delta
		p["rv"] *= 1.0 - delta * 2.0
		p["col"].a = max(0.0, p["col"].a - delta * 0.55)

# ---- DRAWING ----

func _draw():
	if dead:
		_draw_ragdoll()
		return

	var is_slide = (state == State.SLIDE)
	var h = SLIDE_H if is_slide else STAND_H

	if dj_flash > 0.0:
		var fa = dj_flash / 0.20
		var ring_r = 34.0 * (1.3 - fa * 0.5)
		draw_circle(Vector2(0, -h * 0.5), ring_r, Color(0.5, 0.9, 1.0, fa * 0.45))
		draw_arc(Vector2(0, -h * 0.5), ring_r, 0, TAU, 24, Color(0.6, 1.0, 1.0, fa * 0.8), 2.0)

	var glow_c = Color(0.18, 0.52, 1.0, 0.18)
	var neon_c = Color(0.42, 0.82, 1.0, 1.0)

	_draw_stickman(h, glow_c, 9.0)
	_draw_stickman(h, neon_c, 2.8)

func _draw_ragdoll():
	for p in rag_pieces:
		if p["col"].a < 0.02: continue
		var gc = Color(p["col"].r, p["col"].g, p["col"].b, p["col"].a * 0.30)
		if p["type"] == "c":
			draw_circle(p["pos"], p["r"] + 6, gc)
			draw_circle(p["pos"], p["r"], p["col"])
		else:
			var d = Vector2(sin(p["rot"]), -cos(p["rot"])) * p["len"] * 0.5
			draw_line(p["pos"] - d, p["pos"] + d, gc, 8.0)
			draw_line(p["pos"] - d, p["pos"] + d, p["col"], 2.8)

func _draw_stickman(h: float, col: Color, lw: float):
	match state:
		State.SLIDE:        _pose_slide(h, col, lw)
		State.JUMP:         _pose_jump(h, col, lw, false)
		State.DOUBLE_JUMP:  _pose_jump(h, col, lw, true)
		State.CLIMB:        _pose_climb(h, col, lw)
		_:                  _pose_run(h, col, lw)

func _pose_run(h: float, col: Color, lw: float):
	var hr = h * 0.145
	var tl = h * 0.32
	var ll = h * 0.30
	var th = ll * 0.56
	var sh = ll * 0.53

	var phase = anim_t / RUN_CYCLE * TAU
	var s     = sin(phase)
	var s2    = sin(phase + PI)
	var bob   = sin(phase * 2.0) * 3.2

	var hcy = -h + hr + bob * 0.45
	draw_circle(Vector2(3, hcy), hr, col)
	draw_circle(Vector2(3 + hr * 0.52, hcy - hr * 0.07), 1.8, col)

	var ny = hcy + hr
	var hy = ny + tl + bob * 0.3
	draw_line(Vector2(0, ny), Vector2(5, hy), col, lw)

	var sy  = ny + tl * 0.18
	var al  = ll * 0.52
	var asw = s * al * 0.62
	draw_line(Vector2(2, sy), Vector2(2 + asw, sy + al * 0.84), col, lw)
	draw_line(Vector2(2, sy), Vector2(2 - asw, sy + al * 0.84), col, lw)

	var fta = s * 0.64
	var fkx = 5 + sin(fta) * th
	var fky = hy + cos(fta) * th
	var fsa = fta - clamp(s, 0.0, 1.0) * 0.54
	var ffx = fkx + sin(fsa) * sh
	var ffy = fky + cos(fsa) * sh
	draw_line(Vector2(5, hy), Vector2(fkx, fky), col, lw)
	draw_line(Vector2(fkx, fky), Vector2(ffx, ffy), col, lw)

	var bta = s2 * 0.64
	var bkx = 5 + sin(bta) * th
	var bky = hy + cos(bta) * th
	var bsa = bta + clamp(-s2, 0.0, 1.0) * 0.44
	var bfl = abs(s2) * sh * 0.46
	var bfx = bkx + sin(bsa) * sh
	var bfy = bky + cos(bsa) * sh - bfl
	draw_line(Vector2(5, hy), Vector2(bkx, bky), col, lw)
	draw_line(Vector2(bkx, bky), Vector2(bfx, bfy), col, lw)

func _pose_jump(h: float, col: Color, lw: float, dj: bool):
	var hr = h * 0.145
	var tl = h * 0.32
	var ll = h * 0.30
	var th = ll * 0.56
	var sh = ll * 0.53

	var hcy = -h + hr
	draw_circle(Vector2(2, hcy), hr, col)
	draw_circle(Vector2(2 + hr * 0.52, hcy - hr * 0.07), 1.8, col)

	var ny = hcy + hr
	var hy = ny + tl
	draw_line(Vector2(0, ny), Vector2(-3, hy), col, lw)

	var sy = ny + tl * 0.18
	var al = ll * 0.52
	if dj:
		var spin = anim_t * 14.0
		var aw = al * 0.82
		draw_line(Vector2(0, sy), Vector2(aw * cos(spin), sy - abs(sin(spin)) * aw * 0.5), col, lw)
		draw_line(Vector2(0, sy), Vector2(-aw * cos(spin), sy - abs(sin(spin)) * aw * 0.5), col, lw)
	else:
		draw_line(Vector2(0, sy), Vector2(-al * 0.78, sy - al * 0.12), col, lw)
		draw_line(Vector2(0, sy), Vector2( al * 0.78, sy - al * 0.12), col, lw)

	var tuck = 0.82
	var fkx = -th * sin(tuck)
	var fky = hy + th * cos(tuck)
	var ffx = fkx + sh * sin(tuck * 0.38)
	var ffy = fky + sh * cos(tuck * 0.38)
	draw_line(Vector2(-3, hy), Vector2(fkx, fky), col, lw)
	draw_line(Vector2(fkx, fky), Vector2(ffx, ffy), col, lw)

	var bkx = th * sin(tuck * 0.65)
	var bky = hy + th * cos(tuck * 0.65)
	var bfx = bkx + sh * 0.06
	var bfy = bky + sh * 0.58
	draw_line(Vector2(-3, hy), Vector2(bkx, bky), col, lw)
	draw_line(Vector2(bkx, bky), Vector2(bfx, bfy), col, lw)

func _pose_slide(h: float, col: Color, lw: float):
	var hr = h * 0.145
	var cy = -h * 0.5
	draw_circle(Vector2(-h*0.26, cy), hr, col)
	draw_circle(Vector2(-h*0.26 + hr*0.52, cy - hr*0.07), 1.8, col)
	draw_line(Vector2(-h*0.26 + hr, cy), Vector2(h*0.14, cy), col, lw)
	draw_line(Vector2(h*0.14, cy), Vector2(h*0.36, cy + h*0.22), col, lw)
	draw_line(Vector2(h*0.14, cy), Vector2(h*0.30, cy + h*0.30), col, lw)
	draw_line(Vector2(-h*0.06, cy), Vector2(-h*0.26, cy + h*0.15), col, lw)
	draw_line(Vector2(-h*0.06, cy), Vector2(-h*0.18, cy - h*0.14), col, lw)

func _pose_climb(h: float, col: Color, lw: float):
	var hr = h * 0.145
	var progress = 1.0 - clamp(climb_timer / CLIMB_DURATION, 0.0, 1.0)
	var lean = lerp(-8.0, 10.0, progress)
	var hcy = -h + hr
	draw_circle(Vector2(lean * 0.4, hcy), hr, col)
	draw_circle(Vector2(lean * 0.4 + hr * 0.52, hcy - hr * 0.07), 1.8, col)
	var ny = hcy + hr
	var hy = ny + h * 0.32
	draw_line(Vector2(0, ny), Vector2(lean, hy), col, lw)
	var sy = ny + h * 0.10
	var al = h * 0.28
	draw_line(Vector2(0, sy), Vector2(al * 0.55, sy - al * 0.32 * progress), col, lw)
	draw_line(Vector2(0, sy), Vector2(al * 0.88, sy - al * 0.65 * progress), col, lw)
	draw_line(Vector2(lean, hy), Vector2(lean - 12, hy + h*0.26), col, lw)
	draw_line(Vector2(lean - 12, hy + h*0.26), Vector2(lean - 6, hy + h*0.46), col, lw)
	draw_line(Vector2(lean, hy), Vector2(lean + 6, hy + h*0.22), col, lw)
	draw_line(Vector2(lean + 6, hy + h*0.22), Vector2(lean + 14, hy + h*0.44), col, lw)
