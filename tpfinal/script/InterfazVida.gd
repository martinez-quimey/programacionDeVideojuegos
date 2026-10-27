
extends HBoxContainer

@export var value: int = 5:
	set(nuevo_valor):
		var valor_anterior := value
		value = clampi(nuevo_valor, 0, max_value)
		_actualizar_colas()

		if _listo and not _cambiando_maximo and value < valor_anterior:
			_iniciar_temblo()

@export var max_value: int = 5:
	set(nuevo_maximo):
		max_value = maxi(0, nuevo_maximo)

		_cambiando_maximo = true
		value = mini(value, max_value)
		_cambiando_maximo = false

		_crear_colas()

@export var textura_cola: Texture2D
@export var tamano_cola: Vector2 = Vector2(32, 32)
@export var separacion: int = 4

const COLOR_NORMAL := Color.WHITE
const COLOR_PERDIDA := Color(0.35, 0.35, 0.35, 1.0)
const COLOR_ROJO_SUAVE := Color(1.0, 0.55, 0.55, 1.0)

const DURACION_TEMBLO := 0.5
const FUERZA_TEMBLO_X := 4.0
const FUERZA_TEMBLO_Y := 2.0
const VELOCIDAD_TEMBLO := 65.0
const VELOCIDAD_PARPADEO := 2.0

var colas: Array[TextureRect] = []

var _listo := false
var _cambiando_maximo := false

var _posicion_original := Vector2.ZERO
var _tiempo_temblo := 0.0
var _tiempo_parpadeo := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", separacion)

	_posicion_original = position
	_listo = true

	_crear_colas()


func _process(delta: float) -> void:
	# Actualiza el parpadeo cuando queda poca salud.
	if value == 1 or value == 2:
		_tiempo_parpadeo += delta
		_actualizar_colas()

	# Hace temblar la interfaz brevemente al recibir daño.
	if _tiempo_temblo > 0.0:
		_tiempo_temblo = maxf(0.0, _tiempo_temblo - delta)

		if _tiempo_temblo > 0.0:
			var progreso := DURACION_TEMBLO - _tiempo_temblo
			position = _posicion_original + Vector2(
				sin(progreso * VELOCIDAD_TEMBLO) * FUERZA_TEMBLO_X,
				sin(progreso * VELOCIDAD_TEMBLO * 1.4) * FUERZA_TEMBLO_Y
			)
		else:
			position = _posicion_original


func _iniciar_temblo() -> void:
	_tiempo_temblo = DURACION_TEMBLO


func _crear_colas() -> void:
	if not is_inside_tree():
		return

	for cola in colas:
		cola.queue_free()

	colas.clear()

	for i in range(max_value):
		var cola := TextureRect.new()
		cola.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cola.texture = textura_cola
		cola.custom_minimum_size = tamano_cola
		cola.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cola.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		add_child(cola)
		colas.append(cola)

	_actualizar_colas()


func _actualizar_colas() -> void:
	var poca_salud := value == 1 or value == 2

	# El rojo pulsa suavemente, sin ocultar el sprite original.
	var intensidad_roja := (sin(_tiempo_parpadeo * VELOCIDAD_PARPADEO) + 1.0) / 2.0
	var color_peligro := COLOR_NORMAL.lerp(COLOR_ROJO_SUAVE, intensidad_roja)

	for i in range(colas.size()):
		if i < value:
			if poca_salud:
				colas[i].modulate = color_peligro
			else:
				colas[i].modulate = COLOR_NORMAL
		else:
			colas[i].modulate = COLOR_PERDIDA
