extends AbstractEnemy

@onready var particulas: GPUParticles2D = $Particulas
@onready var reproductor_sonido: AudioStreamPlayer2D = $AudioStreamPlayer2D

# Reemplazá esta ruta por la ubicación real de la risa.
@export_file("*.ogg", "*.wav", "*.mp3") var rutaRisa: String = "res://sonidos/enemigos/paraguas/risaParaguas.ogg"

var sonido_risa: AudioStream
var risa_reproducida: bool = false


# ==========================================
# VELOCIDADES
# ==========================================

@export var VELOCIDAD_CAIDA_LENTA: float = 80.0
@export var VELOCIDAD_CAIDA_RAPIDA: float = 700.0


# ==========================================
# ESTADO
# ==========================================

var jugador_debajo: Node2D = null


# ==========================================
# INICIO
# ==========================================

func _ready() -> void:
	super._ready()

	sonido_risa = load(rutaRisa) as AudioStream

	animationPlay("abierto")

	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)

	$DamageArea.body_entered.connect(_on_damage_area_body_entered)


# ==========================================
# FÍSICA
# ==========================================

func _physics_process(_delta: float) -> void:
	if vida <= 0:
		return

	# ==========================================
	# VELOCIDAD DE CAÍDA
	# ==========================================

	if jugador_debajo != null:
		velocity.y = VELOCIDAD_CAIDA_RAPIDA
		animationPlay("cerrado")
	else:
		velocity.y = VELOCIDAD_CAIDA_LENTA
		animationPlay("abierto")

	# ==========================================
	# CAER RECTO
	# ==========================================

	move_and_slide()

	# ==========================================
	# CONTACTO CON EL SUELO
	# ==========================================

	if is_on_floor():
		morir()


# ==========================================
# RISA AL HACER DAÑO
# ==========================================

func reproducir_risa_separada() -> void:
	if risa_reproducida:
		return

	if sonido_risa == null:
		return

	if not is_instance_valid(reproductor_sonido):
		return

	risa_reproducida = true

	# Guardamos la transformación global para que el sonido
	# no cambie de posición al separarlo del paraguas.
	var transformacion_global := reproductor_sonido.global_transform

	# Lo sacamos del paraguas antes de que este sea eliminado.
	remove_child(reproductor_sonido)

	# Lo agregamos a la escena actual, donde podrá terminar de sonar.
	var nivel := get_tree().current_scene
	nivel.add_child(reproductor_sonido)

	reproductor_sonido.global_transform = transformacion_global
	reproductor_sonido.stream = sonido_risa
	reproductor_sonido.play()


# ==========================================
# PARTÍCULAS AL MORIR
# ==========================================

func reproducir_particulas() -> void:
	var transformacion_global := particulas.global_transform

	remove_child(particulas)

	var nivel := get_tree().current_scene
	nivel.add_child(particulas)

	particulas.global_transform = transformacion_global

	particulas.restart()
	particulas.emitting = true


# ==========================================
# JUGADOR ENTRA EN DETECTION AREA
# ==========================================

func _on_detection_body_entered(body: Node2D) -> void:
	if not body.is_in_group("jugador"):
		return

	jugador_debajo = body


# ==========================================
# JUGADOR SALE DE DETECTION AREA
# ==========================================

func _on_detection_body_exited(body: Node2D) -> void:
	if body == jugador_debajo:
		jugador_debajo = null


# ==========================================
# DAMAGE AREA
# ==========================================

func _on_damage_area_body_entered(body: Node2D) -> void:
	# Ignorar el propio paraguas.
	if body == self:
		return

	# ==========================================
	# SI CHOCÓ CON EL JUGADOR
	# ==========================================

	if body.is_in_group("jugador"):
		aplicar_empuje_contacto(body)
		body.herir(1)

		# La risa se desacopla del enemigo y sigue sonando
		# aunque morir() elimine el paraguas.
		reproducir_risa_separada()

	# ==========================================
	# EL PARAGUAS MUERE AL CHOCAR CON UN CUERPO EXTERNO
	# ==========================================

	morir()


# =========================================================
# EMPUJE POR CONTACTO
# =========================================================

func aplicar_empuje_contacto(cuerpo: Node2D) -> void:
	if cuerpo == null:
		return

	var diferencia_x: float = cuerpo.global_position.x - global_position.x
	var direccion_empuje := Vector2.RIGHT

	# Jugador a la izquierda.
	if diferencia_x < -0.1:
		direccion_empuje = Vector2.LEFT

	# Jugador a la derecha.
	elif diferencia_x > 0.1:
		direccion_empuje = Vector2.RIGHT

	# Misma posición horizontal.
	else:
		direccion_empuje = Vector2.RIGHT

	# Empuje reducido.
	cuerpo.retroceso(direccion_empuje, 200)


# ==========================================
# ANIMACIONES
# ==========================================

func animationPlay(nombre: String) -> void:
	animated_sprite.play(nombre)


func comprobar_colision_con_jugador() -> void:
	pass
