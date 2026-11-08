extends Control
## Fondo del taller: pared de ladrillo con friso pintado, suelo de losas, luces de
## fiesta, ventana con haz de sol, tablero de herramientas, cartel, planta y caja.
## Es estático: se dibuja una sola vez y solo se repinta si cambia el tamaño
## o la zona de pared.
##
## main.gd le dice cuál es la zona de pared (la columna central, donde está
## la bici) y dónde empieza el suelo; la decoración se coloca dentro de esa zona
## para no quedar tapada por los paneles laterales.

const Gfx = preload("res://scripts/gfx.gd")

const WAINSCOT := Color(0.1, 0.55, 0.5, 1)

var _wall := Rect2()
var _floor_y := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_layout(wall: Rect2, floor_y: float) -> void:
	if wall == _wall and is_equal_approx(floor_y, _floor_y):
		return
	_wall = wall
	_floor_y = floor_y
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 10.0 or h < 10.0:
		return
	var floor_y := _floor_y if _floor_y > 0.0 else h * 0.82
	var wall := _wall if _wall.size.x > 0.0 else Rect2(0, 0, w, floor_y)
	_draw_wall(w, floor_y)
	_draw_floor(w, h, floor_y)
	_draw_sunbeam(wall, floor_y)
	_draw_window(wall)
	_draw_board(wall)
	_draw_sign(wall)
	_draw_garland(wall)
	_draw_plant(wall, floor_y)
	_draw_toolbox(wall, floor_y)


func _draw_wall(w: float, floor_y: float) -> void:
	# Pared cálida en degradado (bandas).
	var bands := 24
	for i in bands:
		var t := float(i) / float(bands - 1)
		draw_rect(Rect2(0, floor_y * float(i) / float(bands), w, floor_y / float(bands) + 1.0),
			Color(1.0, 0.92, 0.74, 1).lerp(Color(0.96, 0.80, 0.56, 1), t))
	# Ladrillos sutiles: juntas horizontales y verticales alternadas.
	var brick_w := 64.0
	var brick_h := 30.0
	var line := Color(0.75, 0.5, 0.3, 0.16)
	var rows := int(floor_y / brick_h) + 1
	for row in rows:
		var y := float(row) * brick_h
		draw_line(Vector2(0, y), Vector2(w, y), line, 2.0)
		var offset := brick_w * 0.5 * float(row % 2)
		var x := -offset
		while x < w:
			draw_line(Vector2(x, y), Vector2(x, y + brick_h), line, 2.0)
			x += brick_w
	# Friso pintado en la parte baja de la pared, con moldura clara arriba.
	var wain_top := floor_y - 120.0
	draw_rect(Rect2(0, wain_top, w, 120.0), WAINSCOT)
	for i in 6:
		var px := float(i) * w / 5.0
		draw_line(Vector2(px, wain_top + 8), Vector2(px, floor_y), WAINSCOT.darkened(0.18), 3.0)
	draw_rect(Rect2(0, wain_top - 8, w, 12), Color(0.98, 0.95, 0.85, 1))
	draw_line(Vector2(0, wain_top + 4), Vector2(w, wain_top + 4), Color(0.6, 0.45, 0.3, 0.6), 2.0)


func _draw_floor(w: float, h: float, floor_y: float) -> void:
	draw_rect(Rect2(0, floor_y, w, h - floor_y), Color(0.72, 0.55, 0.38, 1))
	var rows := 3
	var tile_h := (h - floor_y) / float(rows)
	for row in rows:
		var tile_w := 100.0 + 40.0 * float(row)   # losas más grandes cerca = perspectiva
		var offset := tile_w * 0.5 * float(row % 2)
		var cols := int(ceil(w / tile_w)) + 1
		for col in cols:
			var x0 := float(col) * tile_w - offset
			var shade := Color(0.80, 0.62, 0.43, 1) if (col + row) % 2 == 0 else Color(0.69, 0.51, 0.35, 1)
			draw_rect(Rect2(x0, floor_y + float(row) * tile_h, tile_w, tile_h), shade)
			draw_line(Vector2(x0, floor_y + float(row) * tile_h), Vector2(x0 + tile_w, floor_y + float(row) * tile_h), Color(0.5, 0.35, 0.22, 0.4), 2.0)
	# Sombra de la pared sobre el suelo y reflejo de luz.
	for i in 6:
		draw_rect(Rect2(0, floor_y + float(i) * 3.0, w, 3.0), Color(0.25, 0.12, 0.05, 0.22 - float(i) * 0.035))
	draw_line(Vector2(0, floor_y), Vector2(w, floor_y), Color(0.4, 0.27, 0.15, 1), 4.0)


func _draw_sunbeam(wall: Rect2, floor_y: float) -> void:
	# Haz de luz que entra por la ventana y cae en diagonal sobre el taller.
	var win_x := wall.position.x + 14.0
	var win_w := minf(wall.size.x * 0.27, 160.0)
	var top_y := wall.position.y + 38.0 + 104.0
	var pts := PackedVector2Array([
		Vector2(win_x + 10.0, top_y), Vector2(win_x + win_w - 10.0, top_y),
		Vector2(win_x + win_w + 230.0, floor_y), Vector2(win_x + 120.0, floor_y)])
	draw_colored_polygon(pts, Color(1.0, 0.97, 0.75, 0.16))
	var pts2 := PackedVector2Array([
		Vector2(win_x + 38.0, top_y), Vector2(win_x + win_w - 38.0, top_y),
		Vector2(win_x + win_w + 120.0, floor_y), Vector2(win_x + 150.0, floor_y)])
	draw_colored_polygon(pts2, Color(1.0, 0.98, 0.8, 0.12))


func _draw_window(wall: Rect2) -> void:
	var win := Rect2(wall.position + Vector2(14, 38), Vector2(minf(wall.size.x * 0.27, 160.0), 104))
	# Cielo con degradado, sol y nube, y marco grueso con alféizar.
	draw_rect(win, Color(0.45, 0.76, 0.95, 1))
	draw_rect(Rect2(win.position + Vector2(0, win.size.y * 0.55), Vector2(win.size.x, win.size.y * 0.45)), Color(0.7, 0.9, 1.0, 1))
	draw_circle(win.position + Vector2(win.size.x * 0.74, win.size.y * 0.3), 16, Color(1.0, 0.95, 0.5, 0.55))
	draw_circle(win.position + Vector2(win.size.x * 0.74, win.size.y * 0.3), 11, Color(1.0, 0.9, 0.4, 1))
	draw_circle(win.position + Vector2(win.size.x * 0.4, win.size.y * 0.22), 7, Color(1, 1, 1, 0.9))
	draw_circle(win.position + Vector2(win.size.x * 0.47, win.size.y * 0.2), 9, Color(1, 1, 1, 0.9))
	# Palma de la ventana: tronco y 5 hojas rellenas en abanico.
	var palm_base := win.position + Vector2(win.size.x * 0.25, win.size.y)
	var palm_top := palm_base + Vector2(4, -win.size.y * 0.45)
	draw_line(palm_base, palm_top, Color(0.45, 0.3, 0.15, 1), 6.0)
	for k in 5:
		var ang := deg_to_rad(-150.0 + float(k) * 30.0)
		var end := palm_top + Vector2(cos(ang), sin(ang)) * 22.0 + Vector2(0, 7)
		var ctrl := palm_top.lerp(end, 0.5) + Vector2(0, -5)
		draw_colored_polygon(Gfx.leaf_poly(palm_top, ctrl, end, 7.0), Color(0.15, 0.5, 0.22, 1))
	draw_rect(win, Color(0.5, 0.32, 0.17, 1), false, 6.0)
	draw_line(Vector2(win.position.x + win.size.x * 0.5, win.position.y),
		Vector2(win.position.x + win.size.x * 0.5, win.end.y), Color(0.5, 0.32, 0.17, 1), 5.0)
	draw_rect(Rect2(win.position.x - 8, win.end.y, win.size.x + 16, 9), Color(0.62, 0.42, 0.22, 1))
	draw_rect(Rect2(win.position.x - 8, win.end.y, win.size.x + 16, 3), Color(0.85, 0.65, 0.4, 1))


func _draw_board(wall: Rect2) -> void:
	var bw := minf(wall.size.x * 0.3, 170.0)
	var board := Rect2(wall.end.x - bw - 14.0, wall.position.y + 38.0, bw, 104.0)
	draw_rect(Rect2(board.position + Vector2(4, 5), board.size), Color(0, 0, 0, 0.2))
	draw_rect(board, Color(0.58, 0.4, 0.22, 1))
	for i in 3:
		draw_line(board.position + Vector2(4, 26 + i * 26), board.position + Vector2(bw - 4, 26 + i * 26), Color(0.45, 0.3, 0.15, 0.5), 2.0)
	draw_rect(board, Color(0.36, 0.22, 0.1, 1), false, 5.0)
	# Siluetas de herramientas con contorno: llave, martillo y bomba.
	var bx := board.position.x + 18.0
	var by := board.position.y + 26.0
	var steel := Color(0.8, 0.8, 0.85, 1)
	var ink := Color(0.15, 0.1, 0.08, 1)
	draw_line(Vector2(bx, by), Vector2(bx + 8, by + 40), ink, 8.0)
	draw_line(Vector2(bx, by), Vector2(bx + 8, by + 40), steel, 5.0)
	draw_circle(Vector2(bx + 4, by - 4), 9, ink)
	draw_circle(Vector2(bx + 4, by - 4), 7, steel)
	draw_line(Vector2(bx + 38, by), Vector2(bx + 38, by + 40), ink, 8.0)
	draw_line(Vector2(bx + 38, by), Vector2(bx + 38, by + 40), Color(0.7, 0.48, 0.22, 1), 5.0)
	draw_rect(Rect2(bx + 26, by - 8, 24, 13), ink)
	draw_rect(Rect2(bx + 28, by - 6, 20, 9), Color(0.5, 0.52, 0.58, 1))
	draw_line(Vector2(bx + 70, by), Vector2(bx + 70, by + 40), ink, 8.0)
	draw_line(Vector2(bx + 70, by), Vector2(bx + 70, by + 40), Color(0.9, 0.3, 0.12, 1), 5.0)
	draw_rect(Rect2(bx + 62, by - 8, 16, 11), ink)
	draw_rect(Rect2(bx + 64, by - 6, 12, 7), Color(0.3, 0.3, 0.35, 1))


func _draw_sign(wall: Rect2) -> void:
	# Cartel colgado de dos cadenas, con el nombre del taller.
	var sign_rect := Rect2(wall.get_center().x - 82.0, wall.position.y + 50.0, 164.0, 40.0)
	draw_line(sign_rect.position + Vector2(24, 0), sign_rect.position + Vector2(24, -14), Color(0.3, 0.3, 0.33, 1), 3.0)
	draw_line(sign_rect.position + Vector2(140, 0), sign_rect.position + Vector2(140, -14), Color(0.3, 0.3, 0.33, 1), 3.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.96, 0.8, 1)
	style.set_corner_radius_all(12)
	style.border_color = Color(0.85, 0.25, 0.1, 1)
	style.set_border_width_all(4)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	draw_style_box(style, sign_rect)
	Gfx.FONT.draw_string_outline(get_canvas_item(), sign_rect.position + Vector2(0, 29),
		"BiciTaller", HORIZONTAL_ALIGNMENT_CENTER, sign_rect.size.x, 26, 6, Color(1, 1, 1, 1))
	Gfx.FONT.draw_string(get_canvas_item(), sign_rect.position + Vector2(0, 29),
		"BiciTaller", HORIZONTAL_ALIGNMENT_CENTER, sign_rect.size.x, 26, Color(0.85, 0.25, 0.1, 1))


func _draw_garland(wall: Rect2) -> void:
	# Guirnalda de bombillos de colores colgada de lado a lado de la pared.
	var left := Vector2(wall.position.x + 4.0, wall.position.y + 4.0)
	var right := Vector2(wall.end.x - 4.0, wall.position.y + 4.0)
	var sag := 26.0
	var colors := [Color(1, 0.35, 0.3), Color(1, 0.85, 0.25), Color(0.3, 0.85, 0.5), Color(0.35, 0.65, 1), Color(1, 0.55, 0.85)]
	var count := 11
	var prev := left
	for i in count * 4 + 1:
		var t := float(i) / float(count * 4)
		var p := left.lerp(right, t) + Vector2(0, sag * 4.0 * t * (1.0 - t))
		if i > 0:
			draw_line(prev, p, Color(0.15, 0.12, 0.1, 1), 2.0)
		prev = p
	for i in count + 1:
		var t := float(i) / float(count)
		var p := left.lerp(right, t) + Vector2(0, sag * 4.0 * t * (1.0 - t))
		var c: Color = colors[i % colors.size()]
		draw_circle(p + Vector2(0, 11), 15, Color(c.r, c.g, c.b, 0.18))
		draw_line(p, p + Vector2(0, 4), Color(0.15, 0.12, 0.1, 1), 3.0)
		draw_circle(p + Vector2(0, 10), 6.5, c)
		draw_circle(p + Vector2(-2, 8), 2.0, Color(1, 1, 1, 0.8))


func _draw_plant(wall: Rect2, floor_y: float) -> void:
	var pot := Vector2(wall.position.x + 36.0, floor_y + 52.0)
	draw_colored_polygon(Gfx.ellipse(pot + Vector2(0, 2), 26, 6), Color(0, 0, 0, 0.2))
	for k in 7:
		var a := -PI * 0.5 + (float(k) - 3.0) * 0.38
		var tip := pot + Vector2(0, -24) + Vector2(cos(a), sin(a)) * 46.0
		draw_colored_polygon(Gfx.leaf_poly(pot + Vector2(0, -24), pot + Vector2(0, -24).lerp(tip - pot, 0.5) + Vector2(sin(a) * 6.0, -4), tip, 11.0),
			Color(0.16, 0.55, 0.24, 1) if k % 2 == 0 else Color(0.22, 0.65, 0.3, 1))
	draw_colored_polygon(PackedVector2Array([
		Vector2(pot.x - 24, pot.y - 28), Vector2(pot.x + 24, pot.y - 28),
		Vector2(pot.x + 17, pot.y), Vector2(pot.x - 17, pot.y)]), Color(0.86, 0.4, 0.15, 1))
	draw_rect(Rect2(pot.x - 26, pot.y - 32, 52, 8), Color(0.95, 0.5, 0.2, 1))


func _draw_toolbox(wall: Rect2, floor_y: float) -> void:
	var box := Rect2(wall.end.x - 84.0, floor_y + 12.0, 70.0, 40.0)
	draw_colored_polygon(Gfx.ellipse(box.get_center() + Vector2(0, 22), 42, 6), Color(0, 0, 0, 0.2))
	draw_rect(box, Color(0.85, 0.25, 0.1, 1))
	draw_rect(box, Color(0.5, 0.12, 0.05, 1), false, 3.0)
	draw_rect(Rect2(box.position.x + 6, box.position.y - 8, 58, 10), Color(0.7, 0.18, 0.08, 1))
	draw_arc(Vector2(box.position.x + 35, box.position.y - 8), 12, PI, TAU, 12, Color(0.5, 0.5, 0.55, 1), 4.0)
	draw_rect(Rect2(box.position.x + 31, box.position.y + 16, 8, 8), Color(0.95, 0.8, 0.2, 1))
	draw_rect(Rect2(box.position.x + 4, box.position.y + 4, 62, 5), Color(1, 1, 1, 0.18))
