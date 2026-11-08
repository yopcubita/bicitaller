#!/usr/bin/env python3
"""Genera los sonidos de BiciTaller (efectos y música) como WAV 16-bit mono.
Todo se sintetiza aquí, sin samples de terceros.
Uso: python3 tools/gen_audio.py   (escribe en assets/audio/)"""
import wave, os
import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
rng = np.random.default_rng(7)


def t_arr(dur):
    return np.arange(int(SR * dur)) / SR


def env(n, attack=0.004, decay=6.0):
    t = np.arange(n) / SR
    e = np.exp(-decay * t)
    a = int(attack * SR)
    if a > 0:
        e[:a] *= np.linspace(0, 1, a)
    return e


def tone(freq, dur, decay=6.0, harm=(1.0,), attack=0.004):
    t = t_arr(dur)
    s = sum(h * np.sin(2 * np.pi * freq * (i + 1) * t) for i, h in enumerate(harm))
    return s * env(len(t), attack, decay)


def glide(f0, f1, dur, decay=4.0, shape="sine"):
    t = t_arr(dur)
    f = np.linspace(f0, f1, len(t))
    ph = 2 * np.pi * np.cumsum(f) / SR
    s = np.sin(ph) if shape == "sine" else np.sign(np.sin(ph)) * 0.6 + np.sin(ph) * 0.4
    return s * env(len(t), 0.004, decay)


def noise(dur, decay=20.0, lp=0.25):
    n = int(SR * dur)
    x = rng.standard_normal(n)
    y = np.zeros(n)
    for i in range(1, n):          # filtro pasa-bajos de un polo
        y[i] = y[i - 1] + lp * (x[i] - y[i - 1])
    return y * env(n, 0.003, decay)


def mix(*parts):
    n = max(len(p[1]) + int(p[0] * SR) for p in parts)
    out = np.zeros(n)
    for start, s in parts:
        i = int(start * SR)
        out[i:i + len(s)] += s
    return out


def save(name, x, peak=0.8):
    x = x / max(np.max(np.abs(x)), 1e-9) * peak
    pcm = (x * 32767).astype("<i2")
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(pcm.tobytes())


NOTE = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
def hz(name, octave):
    return 440.0 * 2 ** ((NOTE[name] - 9 + 12 * (octave - 4)) / 12)


os.makedirs(OUT, exist_ok=True)

# ---- efectos
save("click", tone(1000, 0.05, 60, (1, 0.3)), 0.6)
save("tick", tone(1800, 0.03, 120), 0.45)
save("pump", mix((0, noise(0.13, 14, 0.18) * 0.9), (0, tone(95, 0.12, 22, (1, 0.5)))), 0.85)
save("chain", mix((0, tone(2400, 0.07, 50, (1, 0.5, 0.3))), (0.01, tone(3300, 0.05, 70)), (0, noise(0.03, 90, 0.7) * 0.6)), 0.7)
save("squeak", mix((0, glide(2200, 1100, 0.22, 7) * 0.7), (0, noise(0.2, 15, 0.5) * 0.15)), 0.6)
save("coin", mix((0, tone(hz("E", 6), 0.12, 14, (1, 0.25))), (0.07, tone(hz("B", 6), 0.35, 8, (1, 0.25)))), 0.7)
save("success", mix(*[(i * 0.09, tone(hz(n, o), 0.3, 7, (1, 0.4, 0.15))) for i, (n, o) in enumerate([("C", 5), ("E", 5), ("G", 5), ("C", 6)])]), 0.8)
save("combo", mix(*[(i * 0.06, tone(hz(n, o), 0.28, 8, (1, 0.35))) for i, (n, o) in enumerate([("G", 5), ("B", 5), ("D", 6), ("G", 6), ("B", 6)])]), 0.8)
# timbre de bicicleta: dos ráfagas con parciales inarmónicos
ring = lambda: tone(2637, 0.45, 7) + tone(3951, 0.45, 9) * 0.7 + tone(5230, 0.45, 12) * 0.4
save("bell", mix((0, ring()), (0.17, ring() * 0.9)), 0.7)
save("wrong", glide(190, 140, 0.22, 5, "square") * 0.8, 0.6)
save("fail", mix((0, glide(330, 260, 0.18, 6, "square")), (0.17, glide(260, 190, 0.3, 5, "square"))), 0.6)
save("leave", mix(*[(i * 0.22, glide(f, f * 0.93, 0.28, 4, "square") * 0.8) for i, f in enumerate([392, 349, 311, 233])]), 0.6)
save("gameover", mix(*[(i * 0.3, glide(f, f * 0.97, 0.45, 3.5, "square") * 0.8) for i, f in enumerate([330, 294, 262, 196])]), 0.65)

# ---- música: son sencillo en La menor, 100 bpm, 8 compases (loop)
bpm = 100
beat = 60.0 / bpm
bars = 8
total = bars * 4 * beat
music = np.zeros(int(SR * (total + 1.5)))

def put(start, sig, gain):
    i = int(start * SR)
    music[i:i + len(sig)] += sig[:len(music) - i] * gain

chords = [("A", 2), ("A", 2), ("D", 3), ("D", 3), ("E", 2), ("E", 2), ("A", 2), ("E", 2)]
for bar, (root, octv) in enumerate(chords):
    b0 = bar * 4 * beat
    f = hz(root, octv)
    # tumbao: bajo en el "y" del 2 y en el 4
    for pos in (1.5, 3.0):
        put(b0 + pos * beat, tone(f, 0.45, 5, (1, 0.5, 0.2)), 0.55)
    # claves 3-2
    for pos in (0, 0.75, 1.5, 2.5, 3.0):
        put(b0 + pos * beat, tone(1700, 0.04, 90), 0.25)
    # guitarra/marimba en contratiempo con tríada
    triad = {"A": ["A", "C", "E"], "D": ["D", "F", "A"], "E": ["E", "G", "B"]}[root]
    for pos in (0.5, 1.0, 2.0, 2.5, 3.5):
        for k, n in enumerate(triad):
            put(b0 + pos * beat, tone(hz(n, 4 if n != "C" else 5), 0.22, 11, (1, 0.3)), 0.11)

melody = [  # (compás, posición en pulsos, nota, octava, duración en pulsos)
    (0, 0, "A", 5, 1), (0, 1, "C", 6, 1), (0, 2, "E", 6, 1.5), (0, 3.5, "D", 6, 0.5),
    (1, 0, "C", 6, 1), (1, 1, "A", 5, 1), (1, 2, "G", 5, 2),
    (2, 0, "F", 5, 1), (2, 1, "A", 5, 1), (2, 2, "D", 6, 1.5), (2, 3.5, "C", 6, 0.5),
    (3, 0, "A", 5, 2), (3, 2, "F", 5, 2),
    (4, 0, "E", 5, 1), (4, 1, "G", 5, 1), (4, 2, "B", 5, 1.5), (4, 3.5, "A", 5, 0.5),
    (5, 0, "G", 5, 1), (5, 1, "E", 5, 1), (5, 2, "E", 5, 2),
    (6, 0, "A", 5, 1), (6, 1, "C", 6, 1), (6, 2, "E", 6, 1), (6, 3, "A", 6, 1),
    (7, 0, "G", 6, 1), (7, 1, "E", 6, 1), (7, 2, "B", 5, 2),
]
for bar, pos, n, o, d in melody:
    put((bar * 4 + pos) * beat, tone(hz(n, o), 0.5, 6, (1, 0.45, 0.2)), 0.35)

loop = music[: int(total * SR)].copy()
tail = music[int(total * SR):]
loop[: len(tail)] += tail           # la cola se mezcla al inicio: loop sin corte
save("music", loop, 0.5)
print("listo:", sorted(os.listdir(OUT)))
