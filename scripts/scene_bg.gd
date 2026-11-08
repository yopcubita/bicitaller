extends Control
## Fondo decorativo de atardecer cubano (horizontal), dibujado solo con código.
## Se dibuja una sola vez por cambio de tamaño: no gasta batería.
## Va detrás del contenido de los menús (mouse_filter ignorado).
##
## Composición: el sol se pone en el centro, justo sobre el horizonte, entre la
## columna de texto (izquierda) y la de botones (derecha). Las nubes ocupan el
## hueco entre las dos columnas y las palmas quedan en las esquinas de abajo.

const Gfx = preload("res://scripts/gfx.gd")

## Los menús secundarios (ajustes, créditos...) no dibujan el sol: quedaría
## asomando detrás de los botones.
var show_sun := true
var _top := Color(1.0, 0.88, 0.55, 1)
var _mid := Color(1.0, 0.62, 0.35, 1)
var _bottom := Color(0.85, 0.4, 0.45, 1)
var _ground := Color(0.35, 0.2, 0.35, 1)
var _palm := Color(0.2, 0.25, 0.15, 1)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 10.0 or h < 10.0:
		return
	# Cielo en degradado (bandas).
	var bands := 48
	for i in bands:
		var t := float(i) / float(bands - 1)
		var col: Color
		if t < 0.5:
			col = _top.lerp(_mid, t * 2.0)
		else:
			col = _mid.lerp(_bottom, (t - 0.5) * 2.0)
		draw_rect(Rect2(0, h * float(i) / float(bands), w, h / float(bands) + 1.0), col)
	# Sol con resplandor sobre el horizonte: amarillo fuerte con borde naranja.
	var ground_y := h * 0.86
	if show_sun:
		var sun := Vector2(w * 0.5, ground_y - 76.0)
		draw_circle(sun, 62, Color(1.0, 0.7, 0.15, 0.22))
		draw_circle(sun, 48, Color(1.0, 0.8, 0.25, 0.45))
		draw_circle(sun, 36, Color(1.0, 0.78, 0.1, 1))
		draw_arc(sun, 36, 0, TAU, 48, Color(0.95, 0.55, 0.05, 1), 4.0)
	# Nubes en el hueco entre las dos columnas.
	_cloud(Vector2(w * 0.60, h * 0.16), 0.9)
	_cloud(Vector2(w * 0.66, h * 0.40), 0.6)
	_cloud(Vector2(w * 0.40, h * 0.10), 0.55)
	_skyline(w, ground_y)
	# Suelo oscuro abajo.
	draw_rect(Rect2(0, ground_y, w, h - ground_y), _ground)
	draw_rect(Rect2(0, ground_y, w, 4), Color(0.95, 0.75, 0.4, 1))
	# Palmas en las esquinas.
	_palm_tree(Vector2(w * 0.07, ground_y), 150.0, -1.0)
	_palm_tree(Vector2(w * 0.97, ground_y), 110.0, 1.0)


## Siluetas de edificios al fondo (dos capas), con ventanas encendidas.
func _skyline(w: float, ground_y: float) -> void:
	var layers := [
		{"col": Color(0.78, 0.42, 0.5, 0.55), "hmin": 36.0, "hmax": 84.0, "wmin": 34.0, "wmax": 62.0, "seed": 1.7},
		{"col": Color(0.5, 0.27, 0.42, 0.95), "hmin": 18.0, "hmax": 52.0, "wmin": 40.0, "wmax": 76.0, "seed": 4.3},
	]
	for layer in layers:
		var x := -10.0
		var i := 0
		while x < w:
			var r1 := fposmod(sin(float(i) * 12.9898 + float(layer["seed"])) * 43758.5453, 1.0)
			var r2 := fposmod(sin(float(i) * 78.233 + float(layer["seed"])) * 12345.678, 1.0)
			var bw := lerpf(layer["wmin"], layer["wmax"], r1)
			var bh := lerpf(layer["hmin"], layer["hmax"], r2)
			var col: Color = layer["col"]
			draw_rect(Rect2(x, ground_y - bh, bw, bh + 2.0), col)
			if r1 > 0.55:
				draw_rect(Rect2(x + bw * 0.5 - 3.0, ground_y - bh - 8.0, 6.0, 8.0), col)
			if float(layer["seed"]) > 4.0:
				var wy := ground_y - bh + 8.0
				while wy < ground_y - 8.0:
					var wx := x + 7.0
					while wx < x + bw - 9.0:
						if fposmod(sin(wx * 3.1 + wy * 1.7) * 999.0, 1.0) > 0.55:
							draw_rect(Rect2(wx, wy, 5.0, 6.0), Color(1.0, 0.85, 0.45, 0.85))
						wx += 13.0
					wy += 14.0
			x += bw + 2.0
			i += 1


func _cloud(center: Vector2, scale: float) -> void:
	var white := Color(1, 1, 1, 0.85)
	draw_circle(center, 22 * scale, white)
	draw_circle(center + Vector2(24 * scale, 6 * scale), 16 * scale, white)
	draw_circle(center + Vector2(-24 * scale, 7 * scale), 15 * scale, white)
	draw_circle(center + Vector2(6 * scale, -8 * scale), 14 * scale, white)


func _palm_tree(base: Vector2, height: float, lean: float) -> void:
	var top := base + Vector2(lean * height * 0.25, -height)
	var mid := base.lerp(top, 0.5) + Vector2(lean * 6, 0)
	# Tronco grueso con textura: corteza oscura, franja clara y anillos.
	draw_line(base, mid, _palm, 13.0)
	draw_line(mid, top, _palm, 10.0)
	draw_line(base, mid, Color(0.4, 0.32, 0.2, 1), 5.0)
	draw_line(mid, top, Color(0.4, 0.32, 0.2, 1), 4.0)
	for i in 4:
		var p := base.lerp(top, 0.2 + float(i) * 0.2)
		draw_line(p + Vector2(-7, 0), p + Vector2(7, 0), Color(0.12, 0.16, 0.1, 1), 2.0)
	# Hojas rellenas: 6 frondas que caen a ambos lados de la corona.
	var greens := [Color(0.12, 0.32, 0.12, 1), Color(0.2, 0.45, 0.18, 1)]
	var angles := [-60.0, 240.0, -20.0, 200.0, 15.0, 165.0]
	for i in angles.size():
		var ang := deg_to_rad(angles[i])
		var length := height * 0.5
		var end := top + Vector2(cos(ang), sin(ang)) * length + Vector2(0, length * 0.3)
		# Control en el punto medio, levantado un poco: la curva nunca
		# sobrepasa la punta ni se dobla sobre sí misma.
		var ctrl := top.lerp(end, 0.5) + Vector2(0, -length * 0.12)
		draw_colored_polygon(Gfx.leaf_poly(top, ctrl, end, 16.0), greens[i % 2])
	# Cocos marrones en la corona.
	draw_circle(top + Vector2(-7, 5), 6, Color(0.45, 0.3, 0.15, 1))
	draw_circle(top + Vector2(7, 6), 6, Color(0.5, 0.34, 0.16, 1))
