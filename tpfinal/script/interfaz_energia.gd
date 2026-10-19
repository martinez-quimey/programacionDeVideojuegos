
extends HBoxContainer

@export var value: int = 5:
	set(nuevo_valor):
		value = clampi(nuevo_valor, 0, max_value)
		_actualizar_colas()

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

var colas: Array[TextureRect] = []
var _cambiando_maximo := false


func _ready() -> void:
	add_theme_constant_override("separation", separacion)
	_crear_colas()


func _crear_colas() -> void:
	if not is_inside_tree():
		return

	for cola in colas:
		cola.queue_free()

	colas.clear()

	for i in range(max_value):
		var cola := TextureRect.new()

		cola.texture = textura_cola
		cola.custom_minimum_size = tamano_cola
		cola.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cola.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		add_child(cola)
		colas.append(cola)

	_actualizar_colas()


func _actualizar_colas() -> void:
	for i in range(colas.size()):
		if i < value:
			colas[i].modulate = COLOR_NORMAL
		else:
			colas[i].modulate = COLOR_PERDIDA
