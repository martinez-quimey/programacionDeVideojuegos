
# Player.gd
extends CharacterBody2D

@onready var sonidos: AudioStreamPlayer2D = $Sonidos

@export var esInmuneALaLava: bool = false


# ==========================================
# TRANSICIÓN DE COLISIONES
# ==========================================

const TIEMPO_CAMBIO_COLISION: float = 0.1

var transfiriendo_hitbox_pared: bool = false
var restaurando_hitbox_pared: bool = false

var id_transicion_colision: int = 0
var colision_destino: CollisionShape2D = null
var transicion_colision_en_curso: bool = false

# ==========================================
# ESTADOS
# ==========================================

@onready var estado_manual: EstadoPlayer = $estadoManual
@onready var estado_automatico: EstadoPlayer = $estadoAutomatico

var esta_en_madriguera: bool = false
var estado_actual: EstadoPlayer
var poseeDobleSalto: bool = false


# ==========================================
# VIDA
# ==========================================

var vida_maxima: int
var vida: int

@onready var barraVida = $"../Interfaz/CanvasLayer/Control/InterfazVida"


# ==========================================
# ANIMACIONES Y COLISIONES
# ==========================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animated_sprite_pared: AnimatedSprite2D = $AnimatedSprite2D2

@onready var collision_shape_player: CollisionShape2D = $CollisionShape2D
@onready var collision_shape_player_invertida: CollisionShape2D = $CollisionShape2DInvertida
@onready var collision_pared: CollisionShape2D = $CollisionPared


var mirando_izquierda: bool = false
var cambio_direccion_id: int = 0
var ultima_animacion: String = "quieta"

var movimiento_forzado_activo: bool = false
var tiempo_print_movimiento_forzado: float = 0.0


# ==========================================
# ENERGÍA DE FUEGO
# ==========================================

var energia_maxima: int
var energia_fuego: int

@onready var tiempo_recarga_fuego: Timer = $TiempoRecargaFuego
@onready var barra = $"../Interfaz/CanvasLayer/Control/InterfazEnergia"


# ==========================================
# READY
# ==========================================

func _ready() -> void:
	
	
	# Estados
	estado_manual.activo = true
	estado_automatico.activo = false
	estado_actual = estado_manual

	# Colisiones
	collision_shape_player.scale = Vector2.ONE
	collision_shape_player_invertida.scale = Vector2.ONE

	collision_pared.scale = Vector2.ONE

	collision_pared.set_deferred("disabled", true)


	actualizar_colision_direccion()
	# Vida
	vida_maxima = Settings.getVidaActual()
	vida = Settings.getVidaActual()

	barraVida.max_value = vida_maxima
	barraVida.value = vida

	# Energía
	energia_maxima = Settings.getEnergiaActual()
	energia_fuego = Settings.getEnergiaActual()

	barra.max_value = energia_maxima
	barra.value = energia_fuego

	tiempo_recarga_fuego.one_shot = true

	if not tiempo_recarga_fuego.timeout.is_connected(_on_tiempo_recarga_fuego_timeout):
		tiempo_recarga_fuego.timeout.connect(_on_tiempo_recarga_fuego_timeout)

	# Animación normal
	animated_sprite.animation = "quieta"
	animated_sprite.flip_h = false
	animated_sprite.flip_v = false
	animated_sprite.play()

	# Animación de pared
	animated_sprite_pared.animation = "pared"
	animated_sprite_pared.flip_h = false
	animated_sprite_pared.flip_v = false
	animated_sprite_pared.visible = false
	animated_sprite_pared.play()

	if not estado_actual.deslizandose_pendiente:
		rotation = 0.0

	scale = Vector2.ONE
	ultima_animacion = "quieta"


# ==========================================
# COLISIÓN DIRECCIONAL
# ==========================================


# ==========================================
# TRANSICIÓN DE COLISIONES
# ==========================================
func transicionar_colision(
	nueva_colision: CollisionShape2D
) -> void:

	if nueva_colision == null:
		return

	# No reiniciar una transición idéntica.
	if (
		colision_destino == nueva_colision
		and transicion_colision_en_curso
	):
		return

	# Comprobar si las colisiones ya están correctamente configuradas.
	if colision_destino == nueva_colision:
		var configuracion_correcta := not nueva_colision.disabled

		var colisiones: Array[CollisionShape2D] = [
			collision_shape_player,
			collision_shape_player_invertida,
			collision_pared
		]

		for colision in colisiones:
			if (
				colision != nueva_colision
				and not colision.disabled
			):
				configuracion_correcta = false
				break

		if configuracion_correcta:
			return

	# Guardar si la transición comienza desde el estado de pared.
	var venia_de_pared := (
		colision_destino == collision_pared
		or not collision_pared.disabled
	)

	id_transicion_colision += 1
	var id_actual := id_transicion_colision

	colision_destino = nueva_colision
	transicion_colision_en_curso = true

	restaurando_hitbox_pared = (
		nueva_colision != collision_pared
		and venia_de_pared
	)

	# Activar primero la nueva colisión.
	nueva_colision.set_deferred("disabled", false)

	# Mantener las anteriores durante 0.1 segundos.
	await get_tree().create_timer(
		TIEMPO_CAMBIO_COLISION
	).timeout

	# Si apareció una transición más reciente, cancelar esta.
	if id_actual != id_transicion_colision:
		return

	var colisiones: Array[CollisionShape2D] = [
		collision_shape_player,
		collision_shape_player_invertida,
		collision_pared
	]

	# Desactivar después las colisiones anteriores.
	for colision in colisiones:
		if colision != nueva_colision:
			colision.set_deferred("disabled", true)

	transicion_colision_en_curso = false
	restaurando_hitbox_pared = false

# ==========================================
# COLISIÓN DIRECCIONAL
# ==========================================




# ==========================================
# COLISIÓN DIRECCIONAL
# ==========================================


func actualizar_colision_direccion() -> void:

	# No cambiar las colisiones mientras se está entrando en la pared.
	if transfiriendo_hitbox_pared:
		return

	# Mientras el estado de pared está activo,
	# CollisionPared es la colisión principal.
	if (
		estado_actual != null
		and estado_actual.agarrado_pared
	):
		return

	var colision_nueva: CollisionShape2D

	if mirando_izquierda:
		colision_nueva = collision_shape_player_invertida
	else:
		colision_nueva = collision_shape_player

	transicionar_colision(colision_nueva)

# ==========================================
# INICIAR TRANSFERENCIA A LA PARED
# ==========================================

func iniciar_transferencia_pared(
	normal_pared: Vector2
) -> void:

	if transfiriendo_hitbox_pared:
		return

	if restaurando_hitbox_pared:
		return

	transfiriendo_hitbox_pared = true

	# Invertir el lado de CollisionPared sin guardar
	# la posición anterior.
	if normal_pared.x > 0.0:
		# Pared a la izquierda.
		collision_pared.position.x = -absf(
			collision_pared.position.x
		)
	else:
		# Pared a la derecha.
		collision_pared.position.x = absf(
			collision_pared.position.x
		)

	# Activar la nueva colisión sin desactivar
	# todavía las colisiones del cuerpo.
	collision_pared.set_deferred("disabled", false)


# ==========================================
# RESTAURAR HITBOX AL SOLTARSE DE LA PARED
# ==========================================

func restaurar_hitbox_pared() -> void:

	transfiriendo_hitbox_pared = false

	restaurar_posiciones_pared()

	# La función de dirección activa la nueva hitbox
	# y mantiene CollisionPared durante los 0.1 s.
	actualizar_colision_direccion()


func desactivar_colisiones_direccionales() -> void:
	collision_shape_player.set_deferred("disabled", true)
	collision_shape_player_invertida.set_deferred("disabled", true)


func restaurar_colision_jugador() -> void:
	restaurar_posiciones_pared()

	actualizar_colision_direccion()


# ==========================================
# ANIMACIONES
# ==========================================

func guardar_animacion_actual() -> void:
	if animated_sprite.animation != "":
		ultima_animacion = animated_sprite.animation


func reproducir_animacion(nombre: String) -> void:
	if animated_sprite.animation != nombre:
		animated_sprite.animation = nombre
		animated_sprite.play()
		ultima_animacion = nombre


func animacion_tornado() -> void:
	animated_sprite.play("tornado")


func actualizar_animacion(direccion_animacion: float) -> void:
	if direccion_animacion != 0 and not estado_actual.agarrado_pared:
		mirando_izquierda = direccion_animacion < 0
		actualizar_colision_direccion()

	if movimiento_forzado_activo:
		animated_sprite.visible = true
		animated_sprite_pared.visible = false
		animated_sprite.flip_v = false
		aplicar_direccion_visual()
		reproducir_animacion("salto")
		return

	if estado_actual.agarrado_pared:
		animated_sprite.visible = false
		animated_sprite_pared.visible = true
		return

	if estado_actual.deslizandose_pendiente:
		animated_sprite.visible = true
		animated_sprite_pared.visible = false
		animated_sprite.flip_v = false
		reproducir_animacion("quieta")
		return

	if not is_on_floor():
		animated_sprite.visible = true
		animated_sprite_pared.visible = false
		animated_sprite.flip_v = false
		aplicar_direccion_visual()
		reproducir_animacion("salto")
		return

	animated_sprite.visible = true
	animated_sprite_pared.visible = false
	animated_sprite.flip_v = false
	aplicar_direccion_visual()

	if direccion_animacion != 0:
		reproducir_animacion("correr")
	else:
		reproducir_animacion("quieta")


# ==========================================
# DIRECCIÓN VISUAL
# ==========================================

func establecer_direccion_visual(nueva_direccion: float) -> void:
	if nueva_direccion != 0:
		mirando_izquierda = nueva_direccion < 0
		actualizar_colision_direccion()
		aplicar_direccion_visual()


func aplicar_direccion_visual() -> void:
	if not estado_actual.deslizandose_pendiente:
		rotation = 0.0

	scale = Vector2.ONE

	animated_sprite.visible = true
	animated_sprite_pared.visible = false
	animated_sprite.flip_h = mirando_izquierda
	collision_shape_player.scale = Vector2.ONE
	collision_shape_player_invertida.scale = Vector2.ONE


# ==========================================
# ANIMACIÓN DE SALTO
# ==========================================

func animacion_salto() -> void:
	if not estado_actual.deslizandose_pendiente:
		rotation = 0.0

	animated_sprite.flip_v = false
	aplicar_direccion_visual()
	reproducir_animacion("salto")


# ==========================================
# ANIMACIÓN DE TURBO
# ==========================================

func animacion_turbo() -> void:
	if not estado_actual.deslizandose_pendiente:
		rotation = 0.0

	animated_sprite.flip_v = false
	aplicar_direccion_visual()
	reproducir_animacion("turboFuego")


# ==========================================
# ANIMACIÓN DE PARED
# ==========================================



# ==========================================
# ANIMACIÓN Y COLISIÓN DE PARED
# ==========================================

func animacion_pared(normal_pared: Vector2) -> void:

	animated_sprite.visible = false
	animated_sprite_pared.visible = true
	animated_sprite_pared.animation = "pared"

	scale = Vector2.ONE

	if normal_pared.x > 0.0:
		# Pared a la izquierda:
		# invertir el signo de la posición horizontal.
		collision_pared.position.x = -absf(
			collision_pared.position.x
		)

		animated_sprite_pared.position.x = -absf(
			animated_sprite_pared.position.x
		)

		animated_sprite_pared.flip_h = true
		animated_sprite_pared.flip_v = false
		animated_sprite_pared.rotation = 0.0

	else:
		# Pared a la derecha:
		# restaurar el signo positivo.
		collision_pared.position.x = absf(
			collision_pared.position.x
		)

		animated_sprite_pared.position.x = absf(
			animated_sprite_pared.position.x
		)

		animated_sprite_pared.flip_h = true
		animated_sprite_pared.flip_v = true
		animated_sprite_pared.rotation = deg_to_rad(180.0)

	animated_sprite_pared.play()

	if not estado_actual.deslizandose_pendiente:
		rotation = 0.0

	# Activar la colisión de pared primero.
	# Las colisiones anteriores se desactivan después de 0.1 s.
	transicionar_colision(collision_pared)


# ==========================================
# RESTABLECER VISUAL DEL SUELO
# ==========================================

func restablecer_visual_suelo() -> void:
	if not estado_actual.deslizandose_pendiente:
		rotation = 0.0

	scale = Vector2.ONE
	collision_shape_player.scale = Vector2.ONE
	collision_shape_player_invertida.scale = Vector2.ONE

	restaurar_colision_jugador()

	animated_sprite.visible = true
	animated_sprite_pared.visible = false
	animated_sprite.flip_v = false
	animated_sprite_pared.flip_v = false

	aplicar_direccion_visual()


# ==========================================
# COMPATIBILIDAD CON ESTADOPLAYER
# ==========================================

func restablecer_animacion_vertical() -> void:
	if not estado_actual.deslizandose_pendiente:
		rotation = 0.0

	scale = Vector2.ONE
	collision_shape_player.scale = Vector2.ONE
	collision_shape_player_invertida.scale = Vector2.ONE

	restaurar_colision_jugador()

	animated_sprite.visible = true
	animated_sprite_pared.visible = false
	animated_sprite.flip_v = false
	animated_sprite_pared.flip_v = false

	aplicar_direccion_visual()


# ==========================================
# RESTAURAR ANIMACIÓN
# ==========================================

func restaurar_animacion() -> void:
	animated_sprite.visible = true
	animated_sprite_pared.visible = false

	restaurar_colision_jugador()

	animated_sprite.animation = ultima_animacion
	animated_sprite.play()

	aplicar_direccion_visual()


# ==========================================
# ANIMACIÓN DE HERIDA
# ==========================================

func animacionHerida() -> void:
	while not $Invulnerabilidad.is_stopped():
		animated_sprite.visible = false
		await get_tree().create_timer(0.1).timeout

		animated_sprite.visible = true
		await get_tree().create_timer(0.1).timeout

	animated_sprite.visible = true


# ==========================================
# VIDA
# ==========================================

func getVidaActual() -> int:
	return vida


func getVidaMaxima() -> int:
	return vida_maxima


func aumentar_vida(aumento: int):
	var vidaAumentada = vida + aumento

	if vida_maxima < vidaAumentada:
		vida = vida_maxima
	else:
		vida = vidaAumentada

	actualizar_barra_vida()


func aumentar_energia(aumento: int):
	print("se consumio baya de energia")

	var energiaAumentada = energia_fuego + aumento

	if energia_maxima < energiaAumentada:
		energia_fuego = energia_maxima
	else:
		energia_fuego = energiaAumentada

	actualizar_barra_energia()


func aumentarVidaMax(cantidad: int) -> void:
	if cantidad <= 0:
		return

	vida_maxima += cantidad
	vida += cantidad
	Settings.vidaActual = vida_maxima

	barraVida.max_value = vida_maxima
	barraVida.value = vida


func actualizar_barra_vida() -> void:
	barraVida.max_value = vida_maxima
	barraVida.value = vida


# ==========================================
# ENERGÍA
# ==========================================

func obtener_energia_fuego() -> int:
	return energia_fuego


func getEnergiaMaxima() -> int:
	return energia_maxima


func getEnergiaActual() -> int:
	return energia_fuego


func gastar_energia_fuego(cantidad: int) -> bool:
	if energia_fuego < cantidad:
		return false

	energia_fuego -= cantidad
	actualizar_barra_energia()
	iniciar_recarga_energia()
	return true


func aumentarEnergiaMax(cantidad: int) -> void:
	if cantidad <= 0:
		return

	energia_maxima += cantidad
	energia_fuego += cantidad
	Settings.energiaActual = energia_maxima

	barra.max_value = energia_maxima
	barra.value = energia_fuego


func actualizar_barra_energia() -> void:
	barra.max_value = energia_maxima
	barra.value = energia_fuego


func iniciar_recarga_energia() -> void:
	if energia_fuego >= energia_maxima:
		tiempo_recarga_fuego.stop()
		return

	if tiempo_recarga_fuego.is_stopped():
		tiempo_recarga_fuego.start()


func recargar_energia_fuego() -> void:
	if energia_fuego < energia_maxima:
		energia_fuego += 1
		actualizar_barra_energia()

	if energia_fuego < energia_maxima:
		tiempo_recarga_fuego.start()
	else:
		tiempo_recarga_fuego.stop()


func _on_tiempo_recarga_fuego_timeout() -> void:
	recargar_energia_fuego()


# ==========================================
# DAÑO
# ==========================================

func herir(num: int) -> void:
	estado_actual.herir(num)


# ==========================================
# RETROCESO
# ==========================================

func retroceso(direccion_empuje: Vector2, fuerza: float) -> void:
	estado_actual.retroceso(direccion_empuje, fuerza)


# ==========================================
# MADRIGUERA
# ==========================================

func entrar_madriguera() -> void:
	estado_actual.entrar_madriguera()


func salir_madriguera():
	estado_actual.salir_madriguera()


# ==========================================
# MOVIMIENTO FORZADO
# ==========================================

var impulsos_activos: Dictionary = {}


func movimiento_forzado(impulso, direccion, velocidad):
	var fuerza_impulso = direccion * velocidad
	impulsos_activos[impulso] = fuerza_impulso
	movimiento_forzado_activo = true

	estado_actual.movimiento_forzado(direccion, velocidad)

	if direccion.x != 0:
		establecer_direccion_visual(direccion.x)

	reproducir_animacion("salto")


func detener_movimiento_forzado(impulso):
	if impulsos_activos.has(impulso):
		impulsos_activos.erase(impulso)

	actualizar_movimiento_forzado()


func actualizar_movimiento_forzado():
	var fuerza_total: Vector2 = Vector2.ZERO

	for fuerza in impulsos_activos.values():
		fuerza_total += fuerza

	if fuerza_total == Vector2.ZERO:
		movimiento_forzado_activo = false
		tiempo_print_movimiento_forzado = 0.0
		estado_actual.detener_movimiento_forzado()
		return

	movimiento_forzado_activo = true

	var direccion_total = fuerza_total.normalized()
	var velocidad_total = fuerza_total.length()

	estado_actual.movimiento_forzado(direccion_total, velocidad_total)

	if direccion_total.x != 0:
		establecer_direccion_visual(direccion_total.x)

	reproducir_animacion("salto")


# ==========================================
# DEBUG MOVIMIENTO FORZADO
# ==========================================

func _physics_process(delta):
	if not movimiento_forzado_activo:
		tiempo_print_movimiento_forzado = 0.0
		return

	tiempo_print_movimiento_forzado += delta

	if tiempo_print_movimiento_forzado >= 2.0:
		tiempo_print_movimiento_forzado = 0.0

		print("========================================")
		print("MOVIMIENTO FORZADO: DEBUG")
		print("DIRECCIÓN VELOCIDAD = ", velocity)
		print("DIRECCIÓN NORMALIZADA = ", velocity.normalized())
		print("VELOCIDAD = ", velocity.length())
		print("POSICIÓN = ", global_position)
		print("========================================")

	var cantidad_colisiones = get_slide_collision_count()

	if cantidad_colisiones > 0:
		for i in range(cantidad_colisiones):
			var colision = get_slide_collision(i)
			var objeto = colision.get_collider()

			if objeto == null:
				continue

			print("========================================")
			print("MOVIMIENTO FORZADO: COLISIÓN")
			print("OBJETO QUE FRENA AL PLAYER = ", objeto.name)
			print("RUTA DEL OBJETO = ", objeto.get_path())
			print("TIPO = ", objeto.get_class())
			print("NORMAL DE COLISIÓN = ", colision.get_normal())
			print("POSICIÓN PLAYER = ", global_position)
			print("========================================")


# ==========================================
# SONIDOS
# ==========================================

func _reproducir_sonido(sonido: AudioStream) -> void:
	if sonido == null:
		return

	sonidos.stop()
	sonidos.stream = sonido
	sonidos.play()


func _reproducir_sonido_loop(sonido: AudioStream) -> void:
	if sonido == null:
		return

	sonidos.stop()
	sonidos.stream = sonido
	sonidos.play()
	sonidos.finished.connect(_repetir_sonido_loop, CONNECT_ONE_SHOT)



func restaurar_posiciones_pared() -> void:

	# Volver al lado original usando el signo positivo.
	animated_sprite_pared.position.x = absf(
		animated_sprite_pared.position.x
	)

	collision_pared.position.x = absf(
		collision_pared.position.x
	)

	animated_sprite_pared.flip_h = false
	animated_sprite_pared.flip_v = false
	animated_sprite_pared.rotation = 0.0




func _frenar_sonido() -> void:
	sonidos.stop()


func _repetir_sonido_loop() -> void:
	if sonidos.stream != null:
		sonidos.play()
		sonidos.finished.connect(_repetir_sonido_loop, CONNECT_ONE_SHOT)
