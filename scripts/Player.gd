extends KinematicBody2D
class_name Player

# --- constants ---
const GRAVITY        = 2200.0
const JUMP_FORCE     = -900.0
const SLIDE_DURATION = 0.55
const RUN_SPEED      = 0.0   # player is stationary; world scrolls

# visual sizes
const STAND_H = 80.0
const SLIDE_H = 38.0
const BODY_W  = 28.0

# animation
const RUN_CYCLE = 0.32   # seconds per full stride

enum State { RUN, JUMP, DOUBLE_JUMP, SLIDE, DEAD }

var state       : int   = State.RUN
var velocity    : Vector2 = Vector2.ZERO
var jumps_left  : int   = 2
var slide_timer : float = 0.0
var anim_t      : float = 0.0   # walk-cycle clock
var dead        : bool  = false

# touch input
var touch_start_y : float = -1.0
const SWIPE_DOWN_THRESHOLD = 40.0

onready var col_stand : CollisionShape2D = $CollisionStand
onready var col_slide : CollisionShape2D = $CollisionSlide

signal died

func _ready():
	_set_collision_stand()

func _input(event):
	if dead: return
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start_y = event.position.y
		else:
			if touch_start_y >= 0:
				var dy = event.position.y - touch_start_y
				if dy > SWIPE_DOWN_THRESHOLD:
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
		velocity.y = JUMP_FORCE
		jumps_left -= 1
		state = State.DOUBLE_JUMP if jumps_left == 0 else State.JUMP

func _try_slide():
	if is_on_floor() and state != State.SLIDE:
		state = State.SLIDE
		slide_timer = SLIDE_DURATION
		velocity.y = 0
		_set_collision_slide()

func _physics_process(delta):
	if dead: return

	# gravity
	velocity.y += GRAVITY * delta

	# slide countdown
	if state == State.SLIDE:
		slide_timer -= delta
		if slide_timer <= 0.0:
			_set_collision_stand()
			state = State.RUN if is_on_floor() else State.JUMP

	# move
	velocity = move_and_slide(velocity, Vector2.UP)

	# landing
	if is_on_floor():
		if state != State.SLIDE:
			state = State.RUN
		jumps_left = 2
		velocity.y = 0

	# walk-cycle clock (only while running)
	if state == State.RUN:
		anim_t += delta

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
	emit_signal("died")

# --- drawing ---
func _draw():
	if dead: return
	var is_slide = (state == State.SLIDE)
	var h = SLIDE_H if is_slide else STAND_H
	var glow = Color(0.2, 0.6, 1.0, 0.25)
	var neon = Color(0.35, 0.75, 1.0, 1.0)

	# glow pass
	_draw_stickman(h, is_slide, glow, 7.0)
	# crisp pass
	_draw_stickman(h, is_slide, neon, 2.5)

	update()   # request next frame

func _draw_stickman(h: float, is_slide: bool, col: Color, lw: float):
	var head_r = h * 0.14
	var torso_len = h * 0.30
	var limb_len = h * 0.28

	if is_slide:
		# Sliding pose — body horizontal
		var cx = 0.0
		var cy = -h * 0.5
		draw_circle(Vector2(cx - h * 0.30, cy), head_r, col)
		# torso
		draw_line(Vector2(cx - h*0.30 + head_r, cy),
		          Vector2(cx + h*0.10, cy), col, lw)
		# legs bent back
		draw_line(Vector2(cx + h*0.10, cy),
		          Vector2(cx + h*0.32, cy + h*0.18), col, lw)
		draw_line(Vector2(cx + h*0.10, cy),
		          Vector2(cx + h*0.28, cy + h*0.26), col, lw)
		# arms flat
		draw_line(Vector2(cx - h*0.10, cy - h*0.02),
		          Vector2(cx - h*0.28, cy + h*0.12), col, lw)
		draw_line(Vector2(cx - h*0.10, cy - h*0.02),
		          Vector2(cx - h*0.22, cy - h*0.12), col, lw)
		return

	# Running pose — use sinusoidal walk cycle
	var phase = anim_t / RUN_CYCLE * TAU   # full cycle radian
	var s = sin(phase)
	var s2 = sin(phase + PI)

	var head_cy = -h + head_r
	draw_circle(Vector2(0, head_cy), head_r, col)

	# neck + torso
	var neck_y = head_cy + head_r
	var hip_y  = neck_y + torso_len
	draw_line(Vector2(0, neck_y), Vector2(0, hip_y), col, lw)

	# arms (opposite to legs)
	var shoulder_y = neck_y + torso_len * 0.15
	var arm_swing = s * limb_len * 0.55
	draw_line(Vector2(0, shoulder_y),
	          Vector2(arm_swing, shoulder_y + limb_len * 0.55), col, lw)
	draw_line(Vector2(0, shoulder_y),
	          Vector2(-arm_swing, shoulder_y + limb_len * 0.55), col, lw)

	# legs — thigh + shin per leg
	var thigh = limb_len * 0.55
	var shin  = limb_len * 0.50

	# front leg
	var fThighAngle = s * 0.55          # radians from vertical
	var fKneeX = sin(fThighAngle) * thigh
	var fKneeY = hip_y + cos(fThighAngle) * thigh
	var fShinAngle = fThighAngle - clamp(s, 0.0, 1.0) * 0.45
	var fFootX = fKneeX + sin(fShinAngle) * shin
	var fFootY = fKneeY + cos(fShinAngle) * shin
	draw_line(Vector2(0, hip_y), Vector2(fKneeX, fKneeY), col, lw)
	draw_line(Vector2(fKneeX, fKneeY), Vector2(fFootX, fFootY), col, lw)

	# back leg
	var bThighAngle = s2 * 0.55
	var bKneeX = sin(bThighAngle) * thigh
	var bKneeY = hip_y + cos(bThighAngle) * thigh
	var bShinAngle = bThighAngle + clamp(-s2, 0.0, 1.0) * 0.35
	var bFootLift = abs(s2) * shin * 0.38
	var bFootX = bKneeX + sin(bShinAngle) * shin
	var bFootY = bKneeY + cos(bShinAngle) * shin - bFootLift
	draw_line(Vector2(0, hip_y), Vector2(bKneeX, bKneeY), col, lw)
	draw_line(Vector2(bKneeX, bKneeY), Vector2(bFootX, bFootY), col, lw)
