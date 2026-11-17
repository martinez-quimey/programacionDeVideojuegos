
extends CanvasLayer

@onready var pantalla: Control = $Pantalla
@onready var fondo_negro: ColorRect = $Pantalla/FondoNegro
@onready var nombre_nivel: Label = $Pantalla/NombreNivel


# =========================================================
# INICIAR TRANSICIÓN
# =========================================================



func iniciar(ruta_nivel: String) -> void:

	if pantalla == null or fondo_negro == null or nombre_nivel == null:
		push_error(
			"TRANSICIÓN: no se encontraron Pantalla, FondoNegro o NombreNivel. Revisá los nombres de los nodos."
		)
		return

	# Obtener el nombre del archivo de escena.
	var texto := ruta_nivel.get_file().get_basename()

	# Convertir separadores en espacios.
	texto = texto.replace("_", " ").replace("-", " ").capitalize()

	nombre_nivel.text = texto

	fondo_negro.z_index = 0
	nombre_nivel.z_index = 1
	nombre_nivel.visible = true
	nombre_nivel.modulate = Color.WHITE
	nombre_nivel.add_theme_color_override("font_color", Color.WHITE)

	fondo_negro.visible = true
	pantalla.visible = true
	pantalla.position = Vector2.ZERO
	show()


# =========================================================
# PREPARAR NOMBRE DE LA TRANSICIÓN
# =========================================================

func preparar(nivel: Node) -> void:

	if nivel == null:
		push_error("TRANSICIÓN: se intentó preparar con un nivel null")
		return

	if not "nombre_nivel" in nivel:
		push_error(
			"TRANSICIÓN: el nivel no tiene la propiedad nombre_nivel"
		)
		return

	var texto := str(nivel.get("nombre_nivel"))

	if texto.strip_edges() == "":
		push_warning(
			"TRANSICIÓN: nombre_nivel está vacío"
		)
		texto = "Nivel sin nombre"

	nombre_nivel.text = texto

	nombre_nivel.visible = true
	nombre_nivel.modulate = Color.WHITE
	nombre_nivel.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	fondo_negro.z_index = 0
	nombre_nivel.z_index = 1

	pantalla.position = Vector2.ZERO

	show()


# =========================================================
# REVELAR NIVEL
# =========================================================

func revelar_nivel() -> void:

	var ancho_pantalla := get_viewport().get_visible_rect().size.x

	var tween := create_tween()

	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		pantalla,
		"position:x",
		ancho_pantalla,
		0.9
	)

	await tween.finished

	queue_free()
