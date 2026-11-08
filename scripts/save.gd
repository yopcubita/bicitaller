extends Node
## Autoload "Save": progreso y ajustes guardados en el teléfono (sin internet).
## Archivo: user://bicitaller.cfg — solo guarda lo que existe en este juego.

const PATH := "user://bicitaller.cfg"

var total_coins := 0
var best_bikes := 0
var best_streak := 0
var partidas := 0
var vibracion := true
var sonido := true
var musica := true


func _ready() -> void:
	load_all()


func load_all() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	total_coins = int(cfg.get_value("progreso", "monedas_totales", 0))
	best_bikes = int(cfg.get_value("progreso", "mejor_bicis", 0))
	best_streak = int(cfg.get_value("progreso", "mejor_racha", 0))
	partidas = int(cfg.get_value("progreso", "partidas", 0))
	vibracion = bool(cfg.get_value("ajustes", "vibracion", true))
	sonido = bool(cfg.get_value("ajustes", "sonido", true))
	musica = bool(cfg.get_value("ajustes", "musica", true))


func save_all() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progreso", "monedas_totales", total_coins)
	cfg.set_value("progreso", "mejor_bicis", best_bikes)
	cfg.set_value("progreso", "mejor_racha", best_streak)
	cfg.set_value("progreso", "partidas", partidas)
	cfg.set_value("ajustes", "vibracion", vibracion)
	cfg.set_value("ajustes", "sonido", sonido)
	cfg.set_value("ajustes", "musica", musica)
	var err := cfg.save(PATH)
	if err != OK:
		push_warning("BiciTaller: no se pudo guardar el progreso (error %d)." % err)


func register_day(coins_run: int, bikes: int, streak: int) -> void:
	total_coins += coins_run
	partidas += 1
	if bikes > best_bikes:
		best_bikes = bikes
	if streak > best_streak:
		best_streak = streak
	save_all()
