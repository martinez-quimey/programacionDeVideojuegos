




extends Control

signal creditos_terminados

@onready var viewport_creditos: Control = $Control
@onready var center_container: CenterContainer = $Control/CenterContainer
@onready var vbox: VBoxContainer = $Control/CenterContainer/VBoxContainer

@export_range(1.0, 1000.0, 1.0) var velocidad: float = 150.0

var creditos_finalizados: bool = false
var inicio_detectado: bool = false


func _ready() -> void:

	set_process(false)

	# Evitar que los créditos se vean en su posición original
	# mientras Godot calcula los tamaños.
	visible = false

	actualizar_idioma()

	await get_tree().process_frame
	await get_tree().process_frame

	# Calcular la posición vertical necesaria para que
	# la parte superior de los créditos empiece debajo
	# del área visible.
	var altura_area = viewport_creditos.size.y
	var altura_contenedor = center_container.size.y
	var altura_creditos = vbox.size.y

	center_container.position.y = (
		altura_area
		- (altura_contenedor - altura_creditos) / 2.0
	)

	print("================================")
	print("CRÉDITOS: inicio")
	print("Esquina superior: ", vbox.get_global_rect().position)
	print("Esquina inferior: ", vbox.get_global_rect().end)
	print("Altura del área: ", altura_area)
	print("Altura de créditos: ", altura_creditos)
	print("Velocidad: ", velocidad)
	print("================================")

	visible = true
	set_process(true)


func _process(delta: float) -> void:

	if creditos_finalizados:
		return

	# Mover únicamente el contenedor en vertical.
	# El VBoxContainer conserva su alineación y diseño.
	center_container.position.y -= velocidad * delta

	# Obtener los límites reales de los créditos.
	var rect_creditos = vbox.get_global_rect()
	var rect_area = viewport_creditos.get_global_rect()

	var esquina_superior = rect_creditos.position
	var esquina_inferior = rect_creditos.end

	# Detectar cuándo empiezan a aparecer.
	if not inicio_detectado and esquina_superior.y <= rect_area.position.y:

		inicio_detectado = true
		print("CRÉDITOS: comenzaron a aparecer")

	# Detectar cuándo terminaron de pasar.
	if esquina_inferior.y < rect_area.position.y:

		creditos_finalizados = true
		set_process(false)

		print("CRÉDITOS: terminaron de pasar")

		creditos_terminados.emit()


func actualizar_idioma() -> void:

	var es: bool = Settings.language == "es"

	$Control/CenterContainer/VBoxContainer/Arte.text = (
		"Arte"
		if es
		else "Art"
	)

	$Control/CenterContainer/VBoxContainer/Direccion.text = (
		"Dirección"
		if es
		else "Direction"
	)

	$Control/CenterContainer/VBoxContainer/Assets.text = (
		"Recursos"
		if es
		else "Assets"
	)

	$Control/CenterContainer/VBoxContainer/Label2.text = (
		"Gracias a Crafpix por los recursos de disparo de fuego y de jabalí.\n"
		+ "Miwis, de GodotShaders, creó la base del filtro visual usado en los niveles."
		if es
		else
		"Thanks to Crafpix for the fire projectile and boar assets.\n"
		+ "Miwis from GodotShaders created the base for the visual filter used in the levels."
	)

	$Control/CenterContainer/VBoxContainer/ActuacionDeVoz.text = (
		"Actuación de voz"
		if es
		else "Voice Acting"
	)
