extends KinematicBody2D
class_name Obstacle

var speed : float = 0.0
var col   : Color = Color(1.0, 0.25, 0.25, 1.0)
var glow  : Color = Color(1.0, 0.25, 0.25, 0.3)
var w     : float = 40.0
var h     : float = 60.0
var kind  : String = "low"   # "low" | "high" | "top"

func _ready():
	pass

func setup(p_speed: float, p_kind: String, p_w: float, p_h: float):
	speed = p_speed
	kind  = p_kind
	w = p_w
	h = p_h
	# update collision shape
	var shape = $CollisionShape2D.shape as RectangleShape2D
	shape.extents = Vector2(w * 0.5, h * 0.5)

func _physics_process(delta):
	var _v = move_and_slide(Vector2(-speed, 0), Vector2.UP)
	if position.x < -200:
		queue_free()

func _draw():
	# glow
	draw_rect(Rect2(-w*0.5 - 4, -h*0.5 - 4, w + 8, h + 8),
	          Color(glow.r, glow.g, glow.b, 0.3), true)
	# fill
	draw_rect(Rect2(-w*0.5, -h*0.5, w, h),
	          Color(col.r, col.g, col.b, 0.18), true)
	# border
	draw_rect(Rect2(-w*0.5, -h*0.5, w, h), col, false, 2.5)
	update()
