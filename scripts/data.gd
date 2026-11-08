extends RefCounted
## Datos de BiciTaller: firma, créditos, clientes y averías.

# La firma y la línea de créditos deben aparecer exactamente así en el menú y en los créditos.
# Texto final confirmado por yopcubita, no cambiar.
const SIGNATURE := "Hecho por yopcubita"
const CREDIT_LINE := "Hecho con cariño en Cuba, para que cada bici vuelva a rodar. ¡Gracias por jugar!"

const FAULTS := {
	"goma": {
		"id": "goma", "nombre": "Goma pinchada", "herramienta": "bomba",
		"herramienta_nombre": "Bomba",
		"sintoma": "«¡Ay, la goma está en el piso, pinchada!»",
		"pista": "Hay que inflarla: usa la Bomba y bombea sin parar.",
	},
	"cadena": {
		"id": "cadena", "nombre": "Cadena salida", "herramienta": "llave",
		"herramienta_nombre": "Llave",
		"sintoma": "«¡La cadena se salió y no puedo pedalear!»",
		"pista": "Hay que poner la cadena en su sitio: usa la Llave y toca los eslabones en orden.",
	},
	"frenos": {
		"id": "frenos", "nombre": "Frenos flojos", "herramienta": "destornillador",
		"herramienta_nombre": "Destornillador",
		"sintoma": "«¡No frena! El freno está flojísimo.»",
		"pista": "Hay que ajustar el freno: usa el Destornillador, mantén pulsado y suelta en la zona verde.",
	},
}

const CLIENTS := [
	{"nombre": "Yanelis, la profe", "bici": "Bici de paseo azul", "color": Color(0.2, 0.45, 0.85, 1), "piel": Color(0.85, 0.62, 0.45, 1), "pelo": Color(0.15, 0.1, 0.08, 1), "sombrero": "largo", "accesorio": "libros"},
	{"nombre": "El abuelo Ramón y su Forever", "bici": "Forever clásica verde", "color": Color(0.2, 0.6, 0.3, 1), "piel": Color(0.8, 0.6, 0.45, 1), "pelo": Color(0.9, 0.9, 0.9, 1), "sombrero": "yarey", "accesorio": "baston"},
	{"nombre": "Dani, el mensajero", "bici": "Bici de carga naranja", "color": Color(0.95, 0.5, 0.1, 1), "piel": Color(0.7, 0.5, 0.35, 1), "pelo": Color(0.1, 0.08, 0.06, 1), "sombrero": "gorra", "accesorio": "mochila"},
	{"nombre": "Lili, la niña", "bici": "Bicicletica rosada", "color": Color(0.9, 0.35, 0.55, 1), "piel": Color(0.95, 0.75, 0.6, 1), "pelo": Color(0.25, 0.12, 0.05, 1), "sombrero": "lazo", "accesorio": "flor"},
	{"nombre": "Yusniel, el ciclista", "bici": "Bici de ruta roja", "color": Color(0.85, 0.15, 0.2, 1), "piel": Color(0.75, 0.55, 0.4, 1), "pelo": Color(0.08, 0.06, 0.05, 1), "sombrero": "casco", "accesorio": "botella"},
	{"nombre": "Marta, la vecina", "bici": "Bici de paseo morada", "color": Color(0.55, 0.3, 0.8, 1), "piel": Color(0.85, 0.65, 0.5, 1), "pelo": Color(0.4, 0.25, 0.12, 1), "sombrero": "moño", "accesorio": "bolsa"},
	{"nombre": "Carlos, el panadero", "bici": "Bici de reparto amarilla", "color": Color(0.95, 0.75, 0.1, 1), "piel": Color(0.9, 0.7, 0.5, 1), "pelo": Color(0.2, 0.12, 0.06, 1), "sombrero": "gorro", "accesorio": "cesta_pan"},
	{"nombre": "Aylin, la estudiante", "bici": "Bici plegable celeste", "color": Color(0.15, 0.65, 0.8, 1), "piel": Color(0.8, 0.6, 0.45, 1), "pelo": Color(0.1, 0.08, 0.08, 1), "sombrero": "trenza", "accesorio": "libros"},
]

const TOOL_NAMES := {
	"bomba": "Bomba",
	"llave": "Llave",
	"destornillador": "Destornillador",
}
