extends Control
## Barra del minijuego de frenos: pista, zona verde y aguja.
## Se ve DÓNDE está la zona (antes solo había un número en el texto).

var value := 0.0:
	set(v):
		value = v
		queue_redraw()
var zone_min := 45.0
var zone_max := 75.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 44)


func set_zone(from_value: float, to_value: float) -> void:
	zone_min = from_value
	zone_max = to_value
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.2, 0.15, 0.12, 0.85)
	track.set_corner_radius_all(int(h * 0.5))
	draw_style_box(track, Rect2(0, 0, w, h))
	var inside := value >= zone_min and value <= zone_max
	var zone_x := w * zone_min / 100.0
	var zone_w := w * (zone_max - zone_min) / 100.0
	var green := Color(0.25, 0.85, 0.4, 1) if inside else Color(0.15, 0.6, 0.3, 1)
	draw_rect(Rect2(zone_x, 5, zone_w, h - 10), green)
	var x := clampf(w * value / 100.0, 0.0, w)
	draw_line(Vector2(x, 2), Vector2(x, h - 2), Color(1, 0.95, 0.85, 1), 5.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 8, 0), Vector2(x + 8, 0), Vector2(x, 11)]), Color(1, 0.95, 0.85, 1))
