extends StaticBody2D
class_name Obstacle

var speed : float = 0.0
var w     : float = 40.0
var h     : float = 60.0
var kind  : String = "low"

const C_LOW  = Color(1.00, 0.28, 0.28, 1.0)
const C_MED  = Color(1.00, 0.58, 0.12, 1.0)
const C_TALL = Color(0.85, 0.20, 0.90, 1.0)
const C_HANG = Color(0.20, 0.70, 1.00, 1.0)

var draw_col : Color = C_LOW

func _ready():
        add_to_group("obstacles")

func setup(p_speed: float, p_kind: String, p_w: float, p_h: float):
        speed    = p_speed
        kind     = p_kind
        w        = p_w
        h        = p_h
        var shape = $CollisionShape2D.shape as RectangleShape2D
        shape.extents = Vector2(w * 0.5, h * 0.5)
        if kind == "low":
                draw_col = C_LOW
        elif kind == "med":
                draw_col = C_MED
        elif kind == "tall":
                draw_col = C_TALL
        elif kind == "hang":
                draw_col = C_HANG

func _process(delta):
        position.x -= speed * delta
        if position.x < -220:
                queue_free()
        update()

func _draw():
        var c  = draw_col
        var gc = Color(c.r, c.g, c.b, 0.12)
        var fc = Color(c.r, c.g, c.b, 0.18)

        # Outer glow halo
        draw_rect(Rect2(-w*0.5 - 7, -h*0.5 - 7, w + 14, h + 14),
                  Color(c.r, c.g, c.b, 0.08), true)
        draw_rect(Rect2(-w*0.5 - 3, -h*0.5 - 3, w + 6, h + 6),
                  Color(c.r, c.g, c.b, 0.12), true)

        # Fill
        draw_rect(Rect2(-w*0.5, -h*0.5, w, h), fc, true)

        # Diagonal warning stripes (clipped to rect)
        if kind != "hang":
                var sw = 16.0
                var num = int((w + h) / sw) + 3
                for i in range(num):
                        var x0 = -w*0.5 + i * sw - h
                        var x1 = x0 + h
                        var ax = clamp(x0, -w*0.5, w*0.5)
                        var bx = clamp(x1, -w*0.5, w*0.5)
                        if ax >= bx: continue
                        var ay_off = (ax - x0) / h
                        var by_off = (bx - x0) / h
                        draw_line(
                                Vector2(ax, -h*0.5 + h * ay_off),
                                Vector2(bx, -h*0.5 + h * by_off),
                                Color(c.r, c.g, c.b, 0.22), 3.5
                        )

        # Border
        draw_rect(Rect2(-w*0.5, -h*0.5, w, h), c, false, 2.5)

        # Top edge highlight
        draw_line(Vector2(-w*0.5 + 2, -h*0.5), Vector2(w*0.5 - 2, -h*0.5),
                  Color(1.0, 1.0, 1.0, 0.55), 1.8)

        # Corner marks
        var cm = min(w, h) * 0.14
        draw_line(Vector2(-w*0.5, -h*0.5), Vector2(-w*0.5 + cm, -h*0.5), c, 2.0)
        draw_line(Vector2(-w*0.5, -h*0.5), Vector2(-w*0.5, -h*0.5 + cm), c, 2.0)
        draw_line(Vector2( w*0.5, -h*0.5), Vector2( w*0.5 - cm, -h*0.5), c, 2.0)
        draw_line(Vector2( w*0.5, -h*0.5), Vector2( w*0.5, -h*0.5 + cm), c, 2.0)

        # Hanging obstacle — spikes on bottom
        if kind == "hang":
                var ns = max(2, int(w / 22.0))
                var sw2 = w / ns
                for i in range(ns):
                        var sx = -w*0.5 + sw2 * (float(i) + 0.5)
                        draw_line(Vector2(sx, h*0.5), Vector2(sx, h*0.5 + 14), c, 2.5)
                        var spike_pts = PoolVector2Array([
                                Vector2(sx - 5, h*0.5 + 14),
                                Vector2(sx, h*0.5 + 22),
                                Vector2(sx + 5, h*0.5 + 14)
                        ])
                        draw_colored_polygon(spike_pts, c)
