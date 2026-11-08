extends RefCounted
## Utilidades de dibujo compartidas por las vistas (antes estaban duplicadas).

## Tipografía del juego (Lilita One, licencia OFL: ver assets/fonts/OFL.txt).
const FONT = preload("res://assets/fonts/LilitaOne-Regular.ttf")



static func ellipse(center: Vector2, rx: float, ry: float, steps: int = 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in steps:
		var a := TAU * float(i) / float(steps)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## Hoja rellena: curva cuadrática con ancho que se afina hacia la punta.
static func leaf_poly(start: Vector2, ctrl: Vector2, end: Vector2, width: float) -> PackedVector2Array:
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	var steps := 8
	for j in steps + 1:
		var t := float(j) / float(steps)
		var p := start.lerp(ctrl, t).lerp(ctrl.lerp(end, t), t)
		var d := ctrl.lerp(end, t) - start.lerp(ctrl, t)
		if d.length() < 0.01:
			d = Vector2(1, 0)
		d = d.normalized()
		var n := Vector2(-d.y, d.x)
		var half_w := width * 0.5 * (1.0 - t * 0.85)
		upper.append(p + n * half_w)
		lower.append(p - n * half_w)
	lower.reverse()
	upper.append_array(lower)
	return upper
