extends Node
## Autoload "Sfx": efectos de sonido y música de fondo.
## Los .wav están en assets/audio/ y se generan con tools/gen_audio.py.
## Respeta los ajustes Save.sonido (efectos) y Save.musica (música).

const SOUND_NAMES := [
	"click", "tick", "pump", "chain", "squeak", "coin", "success",
	"combo", "bell", "wrong", "fail", "leave", "gameover",
]
const AUDIO_DIR := "res://assets/audio/"
const POOL_SIZE := 8
const MUSIC_DB_MENU := -9.0
const MUSIC_DB_GAME := -16.0   # más baja durante la partida para oír los efectos

var _sounds := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer


func _ready() -> void:
	# load() en vez de preload(): si los .wav aún no están importados no rompe el script.
	for sound_name in SOUND_NAMES:
		_sounds[sound_name] = load(AUDIO_DIR + sound_name + ".wav")
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.stream = load(AUDIO_DIR + "music.wav")
	_music.volume_db = MUSIC_DB_MENU
	_music.finished.connect(_on_music_finished)
	add_child(_music)
	refresh_music()


## Reproduce un efecto. `pitch` cambia el tono (p. ej. el bombeo sube al llenarse).
func play(sound: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not Save.sonido or not _sounds.has(sound):
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = _sounds[sound]
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


func refresh_music() -> void:
	if Save.musica:
		if not _music.playing:
			_music.play()
	else:
		_music.stop()


## Baja la música mientras se juega y la sube en los menús.
func set_in_game(in_game: bool) -> void:
	_music.volume_db = MUSIC_DB_GAME if in_game else MUSIC_DB_MENU


func _on_music_finished() -> void:
	if Save.musica:
		_music.play()


func _exit_tree() -> void:
	# Soltar los recursos de audio al cerrar (evita avisos de "recursos en uso").
	_music.stop()
	_music.stream = null
	for p in _players:
		p.stop()
		p.stream = null
