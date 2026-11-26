
extends Control


signal volver


const RUTA_OPCIONES_SONIDO := "user://opciones.cfg"


@onready var sonido_slider: HSlider = $CenterContainer/VBoxContainer/SonidoSlider
@onready var musica_slider: HSlider = $CenterContainer/VBoxContainer/MusicaSlider
@onready var voces_slider: HSlider = $CenterContainer/VBoxContainer/VocesSlider

@onready var label_sonido: Label = $CenterContainer/VBoxContainer/LabelSonido
@onready var label_musica: Label = $CenterContainer/VBoxContainer/LabelMusica
@onready var label_voces: Label = $CenterContainer/VBoxContainer/LabelVoces

@onready var back_button: Button = $CenterContainer/VBoxContainer/BackButton


# =========================================================
# INICIALIZACIÓN
# =========================================================

func _enter_tree() -> void:
	# Permitir utilizar esta pantalla aunque el juego esté pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:

	_configurar_deslizadores()
	_cargar_volumenes()

	if not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)

	actualizar_idioma()


# =========================================================
# CONFIGURAR DESLIZADORES
# =========================================================

func _configurar_deslizadores() -> void:

	for slider in [sonido_slider, musica_slider, voces_slider]:

		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1


	if not sonido_slider.value_changed.is_connected(_on_sonido_slider_changed):
		sonido_slider.value_changed.connect(_on_sonido_slider_changed)


	if not musica_slider.value_changed.is_connected(_on_musica_slider_changed):
		musica_slider.value_changed.connect(_on_musica_slider_changed)


	if not voces_slider.value_changed.is_connected(_on_voces_slider_changed):
		voces_slider.value_changed.connect(_on_voces_slider_changed)


# =========================================================
# MODIFICAR VOLUMEN
# =========================================================

func _on_sonido_slider_changed(valor: float) -> void:

	_cambiar_volumen_bus("Sonido", valor)
	_guardar_volumenes()


func _on_musica_slider_changed(valor: float) -> void:

	_cambiar_volumen_bus("Musica", valor)
	_guardar_volumenes()


func _on_voces_slider_changed(valor: float) -> void:

	_cambiar_volumen_bus("Voces", valor)
	_guardar_volumenes()


func _cambiar_volumen_bus(nombre_bus: String, valor: float) -> void:

	var indice_bus := AudioServer.get_bus_index(nombre_bus)

	if indice_bus == -1:
		push_warning("No se encontró el bus de audio: " + nombre_bus)
		return

	if valor <= 0.0:

		AudioServer.set_bus_volume_db(indice_bus, -80.0)

	else:

		AudioServer.set_bus_volume_db(
			indice_bus,
			linear_to_db(valor / 100.0)
		)


# =========================================================
# GUARDAR VOLUMENES
# =========================================================

func _guardar_volumenes() -> void:

	var efectos: float = sonido_slider.value
	var musica: float = musica_slider.value
	var voces: float = voces_slider.value


	# Mantener también los valores en memoria.
	Save.volumenes_memoria = {
		"efectos": efectos,
		"musica": musica,
		"voces": voces
	}


	var config := ConfigFile.new()

	config.set_value("sonido", "efectos", efectos)
	config.set_value("sonido", "musica", musica)
	config.set_value("sonido", "voces", voces)


	var error := config.save(RUTA_OPCIONES_SONIDO)

	if error != OK:
		push_error(
			"No se pudieron guardar las opciones de sonido. Error: "
			+ str(error)
		)


# =========================================================
# CARGAR VOLUMENES
# =========================================================

func _cargar_volumenes() -> void:

	var config := ConfigFile.new()

	var error := config.load(RUTA_OPCIONES_SONIDO)


	if error == OK:

		sonido_slider.set_value_no_signal(
			float(config.get_value("sonido", "efectos", 50.0))
		)

		musica_slider.set_value_no_signal(
			float(config.get_value("sonido", "musica", 50.0))
		)

		voces_slider.set_value_no_signal(
			float(config.get_value("sonido", "voces", 50.0))
		)

	else:

		sonido_slider.set_value_no_signal(50.0)
		musica_slider.set_value_no_signal(50.0)
		voces_slider.set_value_no_signal(50.0)

		_guardar_volumenes()


	# Aplicar los valores al mezclador de audio.
	_cambiar_volumen_bus("Sonido", sonido_slider.value)
	_cambiar_volumen_bus("Musica", musica_slider.value)
	_cambiar_volumen_bus("Voces", voces_slider.value)


# =========================================================
# IDIOMA
# =========================================================

func actualizar_idioma() -> void:

	var es: bool = Settings.language == "es"

	label_sonido.text = "Efectos de sonido" if es else "Sound Effects"
	label_musica.text = "Música" if es else "Music"
	label_voces.text = "Voces" if es else "Voices"

	back_button.text = "Volver" if es else "Back"


# =========================================================
# VOLVER
# =========================================================

func _on_back_button_pressed() -> void:

	volver.emit()


# =========================================================
# CONTROL CON TECLADO
# =========================================================

func _input(event: InputEvent) -> void:

	if not visible:
		return

	if not event is InputEventKey:
		return

	var tecla := event as InputEventKey

	if not tecla.pressed:
		return


	var izquierda := (
		tecla.physical_keycode == KEY_LEFT
		or tecla.keycode == KEY_LEFT
	)

	var derecha := (
		tecla.physical_keycode == KEY_RIGHT
		or tecla.keycode == KEY_RIGHT
	)

	if not izquierda and not derecha:
		return


	var enfocado := get_viewport().gui_get_focus_owner()

	if not enfocado is HSlider:
		return


	var direccion := -1.0 if izquierda else 1.0

	var incremento := 5.0 if tecla.echo else 1.0

	enfocado.value += direccion * incremento

	get_viewport().set_input_as_handled()
