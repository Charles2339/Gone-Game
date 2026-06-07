extends KinematicBody2D
class_name Player

signal died

const GRAVITY         = 2600.0
const JUMP_FORCE      = -1020.0
const JUMP2_FORCE     = -860.0
const SLIDE_DURATION  = 0.52
const CLIMB_DURATION  = 0.36
const LAND_SQUASH_DUR = 0.12

const STAND_H  = 88.0
const SLIDE_H  = 40.0
const RUN_CYCLE = 0.24

enum State { RUN, JUMP, DOUBLE_JUMP, SLIDE, CLIMB, DEAD }

var state        : int    = State.RUN
var velocity     : Vector2 = Vector2.ZERO
var jumps_left   : int    = 2
var slide_timer  : float  = 0.0
var climb_timer  : float  = 0.0
var anim_t       : float  = 0.0
var dead         : bool   = false
var game_speed   : float  = 480.0

var dj_flash     : float  = 0.0
var land_squash  : float  = 0.0   # 0..LAND_SQUASH_DUR → squash on landing
var was_on_floor : bool   = false

var rag_pieces   : Array  = []
const RAG_GRAVITY = 1200.0

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
		if event.scancode == KEY_SPACE or event.scancode == KEY_UP:
			_try_jump()
		elif event.scancode == KEY_DOWN or event.scancode == KEY_S:
			_try_slide()

func _try_jump():
	if state == State.SLIDE: return
	if jumps_left > 0:
		jumps_left -= 1
		velocity.y = JUMP_FORCE if jumps_left == 1 else JUMP2_FORCE
		state = State.JUMP if jumps_left == 1 else State.DOUBLE_JUMP
		if state == State.DOUBLE_JUMP:
			dj_flash = 0.22
		land_squash = 0.0
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
	var boost = clamp(obs_h * 8.5 + 390.0, 520.0, 800.0)
	velocity.y = -boost
	anim_t = 0.0

func _physics_process(delta):
	if dead:
		_update_ragdoll(delta)
		update()
		return

	dj_flash    = max(0.0, dj_flash - delta)
	land_squash = max(0.0, land_squash - delta)

	if state == State.CLIMB:
		velocity.y += GRAVITY * 0.26 * delta
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

	var on_floor_now = is_on_floor()
	if on_floor_now:
		if not was_on_floor and (state == State.JUMP or state == State.DOUBLE_JUMP):
			land_squash = LAND_SQUASH_DUR
			anim_t = 0.0
		if state != State.SLIDE and state != State.CLIMB:
			state = State.RUN
		jumps_left = 2
		velocity.y = 0.0
	was_on_floor = on_floor_now

	anim_t += delta
	update()

func _handle_obstacle_collision(coll):
	if dead: return
	var normal = coll.normal
	var obs    = coll.collider

	if normal.y < -0.55:
		if not was_on_floor and (state == State.JUMP or state == State.DOUBLE_JUMP):
			land_squash = LAND_SQUASH_DUR
			anim_t = 0.0
		if state != State.SLIDE and state != State.CLIMB:
			state = State.RUN
		jumps_left = 2
		velocity.y = 0.0
	elif normal.y > 0.55:
		if state != State.SLIDE:
			die()
		else:
			velocity.y = max(velocity.y, 0.0)
	elif abs(normal.x) > 0.35:
		if state == State.CLIMB: return
		if obs.kind == "low" and game_speed < 660.0 and obs.h < 82.0:
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
	dead  = true
	state = State.DEAD
	_spawn_ragdoll()
	emit_signal("died")

func _spawn_ragdoll():
	rag_pieces.clear()
	var neon = Color(0.42, 0.82, 1.0, 1.0)
	var red  = Color(1.0,  0.35, 0.35, 1.0)
	var bvx  = -90.0  - randf() * 60.0
	var bvy  = -280.0 - randf() * 130.0

	# Head
	rag_pieces.append({
		"type": "c", "pos": Vector2(3, -82), "r": 13.0, "col": neon.duplicate(),
		"vel": Vector2(bvx + randf()*50-25, bvy - 110 - randf()*90),
		"rot": 0.0, "rv": randf()*8-4.0
	})
	# Torso
	rag_pieces.append({
		"type": "l", "pos": Vector2(0, -54), "len": 30.0, "col": neon.duplicate(),
		"vel": Vector2(bvx, bvy + randf()*40),
		"rot": 0.2, "rv": randf()*5-2.5
	})
	# Arms
	for sx in [1, -1]:
		rag_pieces.append({
			"type": "l", "pos": Vector2(sx*8, -66), "len": 22.0, "col": neon.duplicate(),
			"vel": Vector2(bvx + sx * 200 + randf()*60, bvy - randf()*90),
			"rot": float(sx) * 1.4, "rv": float(sx) * (randf()*12+6)
		})
	# Legs
	for sx in [1, -1]:
		rag_pieces.append({
			"type": "l", "pos": Vector2(sx*6, -20), "len": 26.0, "col": red.duplicate(),
			"vel": Vector2(bvx + sx*130 + randf()*50, bvy + 90 + randf()*90),
			"rot": float(sx) * 0.8, "rv": float(-sx) * (randf()*10+5)
		})

func _update_ragdoll(delta):
	for p in rag_pieces:
		p["vel"].y += RAG_GRAVITY * delta
		p["vel"].x *= (1.0 - delta * 1.2)  # slight air drag on x
		p["pos"]   += p["vel"] * delta
		p["rot"]   += p["rv"] * delta
		p["rv"]    *= 1.0 - delta * 2.2
		p["col"].a  = max(0.0, p["col"].a - delta * 0.50)

# ---- DRAWING ----

func _draw():
	if dead:
		_draw_ragdoll()
		return

	var is_slide = (state == State.SLIDE)
	var h = SLIDE_H if is_slide else STAND_H

	# Landing squash/stretch scale
	var sq_t   = 1.0 - clamp(land_squash / LAND_SQUASH_DUR, 0.0, 1.0)
	var sq_y   = 1.0 - 0.22 * sin(sq_t * PI)
	var sq_x   = 1.0 + 0.18 * sin(sq_t * PI)

	if dj_flash > 0.0:
		var fa     = dj_flash / 0.22
		var ring_r = 36.0 * (1.3 - fa * 0.5)
		draw_circle(Vector2(0, -h * 0.5), ring_r, Color(0.5, 0.9, 1.0, fa * 0.40))
		draw_arc(Vector2(0, -h * 0.5), ring_r, 0, TAU, 28, Color(0.6, 1.0, 1.0, fa * 0.85), 2.0)
		# Particles
		for i in range(6):
			var angle = dj_flash * 18.0 + i * TAU / 6.0
			var pr    = ring_r * (1.1 + fa * 0.3)
			var pp    = Vector2(cos(angle)*pr, sin(angle)*pr) + Vector2(0, -h*0.5)
			draw_circle(pp, 2.5, Color(0.7, 1.0, 1.0, fa * 0.7))

	var glow_c = Color(0.18, 0.52, 1.0, 0.18)
	var neon_c = Color(0.42, 0.82, 1.0, 1.0)

	draw_set_transform(Vector2(0, 0), 0.0, Vector2(sq_x, sq_y))
	_draw_stickman(h, glow_c, 9.0)
	_draw_stickman(h, neon_c, 2.8)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_ragdoll():
	for p in rag_pieces:
		if p["col"].a < 0.02: continue
		var gc = Color(p["col"].r, p["col"].g, p["col"].b, p["col"].a * 0.28)
		if p["type"] == "c":
			draw_circle(p["pos"], p["r"] + 6, gc)
			draw_circle(p["pos"], p["r"], p["col"])
		else:
			var d = Vector2(sin(p["rot"]), -cos(p["rot"])) * p["len"] * 0.5
			draw_line(p["pos"] - d, p["pos"] + d, gc,       8.0)
			draw_line(p["pos"] - d, p["pos"] + d, p["col"], 2.8)

func _draw_stickman(h: float, col: Color, lw: float):
	if state == State.SLIDE:
		_pose_slide(h, col, lw)
	elif state == State.JUMP:
		_pose_jump(h, col, lw, false)
	elif state == State.DOUBLE_JUMP:
		_pose_jump(h, col, lw, true)
	elif state == State.CLIMB:
		_pose_climb(h, col, lw)
	else:
		_pose_run(h, col, lw)

func _pose_run(h: float, col: Color, lw: float):
	var hr  = h * 0.145
	var tl  = h * 0.32
	var ll  = h * 0.30
	var th  = ll * 0.56
	var sh  = ll * 0.54

	var phase = anim_t / RUN_CYCLE * TAU
	var s     = sin(phase)
	var s2    = sin(phase + PI)
	# Up-down torso bob
	var bob   = sin(phase * 2.0) * 3.5
	# Forward lean based on speed
	var lean  = clamp((game_speed - 480.0) / 380.0, 0.0, 1.0) * 6.0

	var hcy = -h + hr + bob * 0.45
	# Head
	draw_circle(Vector2(3 + lean, hcy), hr, col)
	# Eye
	draw_circle(Vector2(3 + lean + hr * 0.52, hcy - hr * 0.07), 1.8, col)

	var ny = hcy + hr
	var hy = ny + tl + bob * 0.3
	# Torso — slight forward lean
	draw_line(Vector2(0, ny), Vector2(5 + lean, hy), col, lw)

	# Arms with proper swing
	var sy  = ny + tl * 0.18
	var al  = ll * 0.54
	var asw = s * al * 0.68
	draw_line(Vector2(2, sy), Vector2(2 + asw,  sy + al * 0.82), col, lw)
	draw_line(Vector2(2, sy), Vector2(2 - asw,  sy + al * 0.82), col, lw)

	# Front leg
	var fta = s * 0.66
	var fkx = 5 + sin(fta) * th
	var fky = hy + cos(fta) * th
	var fsa = fta - clamp(s, 0.0, 1.0) * 0.55
	var ffx = fkx + sin(fsa) * sh
	var ffy = fky + cos(fsa) * sh
	draw_line(Vector2(5, hy), Vector2(fkx, fky), col, lw)
	draw_line(Vector2(fkx, fky), Vector2(ffx, ffy), col, lw)
	# Foot dot for clarity
	if lw < 4.0:
		draw_circle(Vector2(ffx, ffy), lw * 0.8, col)

	# Back leg
	var bta = s2 * 0.66
	var bkx = 5 + sin(bta) * th
	var bky = hy + cos(bta) * th
	var bsa = bta + clamp(-s2, 0.0, 1.0) * 0.44
	var bfl = abs(s2) * sh * 0.46
	var bfx = bkx + sin(bsa) * sh
	var bfy = bky + cos(bsa) * sh - bfl
	draw_line(Vector2(5, hy), Vector2(bkx, bky), col, lw)
	draw_line(Vector2(bkx, bky), Vector2(bfx, bfy), col, lw)

func _pose_jump(h: float, col: Color, lw: float, dj: bool):
	var hr  = h * 0.145
	var tl  = h * 0.32
	var ll  = h * 0.30
	var th  = ll * 0.56
	var sh  = ll * 0.54

	# Body rises as velocity increases
	var rise = clamp(-velocity.y / 1200.0, 0.0, 1.0)

	var hcy = -h + hr - rise * 4.0
	draw_circle(Vector2(2, hcy), hr, col)
	draw_circle(Vector2(2 + hr * 0.52, hcy - hr * 0.07), 1.8, col)

	var ny = hcy + hr
	var hy = ny + tl
	draw_line(Vector2(0, ny), Vector2(-2, hy), col, lw)

	var sy = ny + tl * 0.18
	var al = ll * 0.54
	if dj:
		var spin = anim_t * 16.0
		var aw   = al * 0.88
		draw_line(Vector2(0, sy), Vector2( aw * cos(spin), sy - abs(sin(spin)) * aw * 0.55), col, lw)
		draw_line(Vector2(0, sy), Vector2(-aw * cos(spin), sy - abs(sin(spin)) * aw * 0.55), col, lw)
	else:
		# Arms spread wide on ascent, tuck on descent
		var arm_spread = lerp(0.88, 0.55, clamp(-velocity.y / 800.0, 0.0, 1.0))
		draw_line(Vector2(0, sy), Vector2(-al * arm_spread, sy - al * 0.10), col, lw)
		draw_line(Vector2(0, sy), Vector2( al * arm_spread, sy - al * 0.10), col, lw)

	# Leg tuck — tighter on way up, extends on way down
	var tuck = lerp(0.50, 0.88, clamp(-velocity.y / 800.0, 0.0, 1.0))
	var fkx  = -th * sin(tuck)
	var fky  = hy + th * cos(tuck)
	var ffx  = fkx + sh * sin(tuck * 0.4)
	var ffy  = fky + sh * cos(tuck * 0.4)
	draw_line(Vector2(-2, hy), Vector2(fkx, fky), col, lw)
	draw_line(Vector2(fkx, fky), Vector2(ffx, ffy), col, lw)

	var bkx = th * sin(tuck * 0.65)
	var bky = hy + th * cos(tuck * 0.65)
	var bfx = bkx + sh * 0.06
	var bfy = bky + sh * 0.58
	draw_line(Vector2(-2, hy), Vector2(bkx, bky), col, lw)
	draw_line(Vector2(bkx, bky), Vector2(bfx, bfy), col, lw)

func _pose_slide(h: float, col: Color, lw: float):
	var hr = h * 0.145
	var cy = -h * 0.5
	var ox = -h * 0.26
	# Head
	draw_circle(Vector2(ox, cy), hr, col)
	draw_circle(Vector2(ox + hr * 0.52, cy - hr * 0.07), 1.8, col)
	# Torso horizontal
	draw_line(Vector2(ox + hr, cy), Vector2(h * 0.16, cy), col, lw)
	# Front leg extended
	draw_line(Vector2(h * 0.16, cy), Vector2(h * 0.38, cy + h * 0.22), col, lw)
	draw_line(Vector2(h * 0.38, cy + h * 0.22), Vector2(h * 0.48, cy + h * 0.22), col, lw)
	# Back leg bent
	draw_line(Vector2(h * 0.16, cy), Vector2(h * 0.30, cy + h * 0.30), col, lw)
	draw_line(Vector2(h * 0.30, cy + h * 0.30), Vector2(h * 0.36, cy + h * 0.20), col, lw)
	# Arms back
	draw_line(Vector2(-h * 0.06, cy), Vector2(-h * 0.28, cy + h * 0.14), col, lw)
	draw_line(Vector2(-h * 0.06, cy), Vector2(-h * 0.18, cy - h * 0.13), col, lw)

func _pose_climb(h: float, col: Color, lw: float):
	var hr       = h * 0.145
	var progress = 1.0 - clamp(climb_timer / CLIMB_DURATION, 0.0, 1.0)
	var lean     = lerp(-10.0, 14.0, progress)

	var hcy = -h + hr
	draw_circle(Vector2(lean * 0.4, hcy), hr, col)
	draw_circle(Vector2(lean * 0.4 + hr * 0.52, hcy - hr * 0.07), 1.8, col)

	var ny = hcy + hr
	var hy = ny + h * 0.32
	draw_line(Vector2(0, ny), Vector2(lean, hy), col, lw)

	var sy = ny + h * 0.10
	var al = h * 0.28
	# Arms reach forward toward obstacle
	var arm_reach = sin(progress * PI) * 0.35
	draw_line(Vector2(0, sy), Vector2(al * (0.55 + arm_reach), sy - al * (0.32 + arm_reach) * progress), col, lw)
	draw_line(Vector2(0, sy), Vector2(al * 0.88, sy - al * 0.65 * progress), col, lw)

	# Legs push off
	var step = sin(progress * PI * 1.5)
	draw_line(Vector2(lean, hy), Vector2(lean - 14 + step * 4, hy + h * 0.26), col, lw)
	draw_line(Vector2(lean - 14 + step * 4, hy + h * 0.26), Vector2(lean - 8  + step * 2, hy + h * 0.48), col, lw)
	draw_line(Vector2(lean, hy), Vector2(lean + 8,            hy + h * 0.22), col, lw)
	draw_line(Vector2(lean + 8,            hy + h * 0.22), Vector2(lean + 16, hy + h * 0.42), col, lw)
