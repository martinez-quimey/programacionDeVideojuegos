extends Node2D

@onready var weapon_tip: Node2D = $WeaponTip
@onready var fx_anim: AnimationPlayer = $FXAnim

@export var projectile_scene: PackedScene

var projectile_container: Node
var fire_tween: Tween

var _tracking_fire: bool = false


# Hacemos esto ya que si solo hacemos tracking del mouse al principio
# de la función fire(), para el momento en que se instancia el proyectil
# puede que el objetivo se haya movido, con esto nos aseguramos de estar
# trackeando el mouse durante toda la animación. Se podría también solo
# dejarlo en el _fire() antes de instanciar el proyectil, pero dónde está
# la gracia en eso?
func process_input() -> void:
	if _tracking_fire:
		look_at(get_global_mouse_position())


func fire() -> void:
	## Mato al tween antes de disparar para que no me cambie la rotación
	if fire_tween != null:
		fire_tween.kill()
	_tracking_fire = true
	
	## No disparo de inmediato, sino que delego a una animación de disparo
	fx_anim.play(&"fire")


## La animación de disparo llama a esta función que va a ser la que instancie
## el proyectil
func _fire() -> void:
	_tracking_fire = false
	var projectile_instance: Node = projectile_scene.instantiate()
	projectile_container.add_child(projectile_instance)
	projectile_instance.initialize(
		weapon_tip.global_position,
		global_position.direction_to(weapon_tip.global_position)
	)
	
	## Y por último animo el retorno a la posición de inicio del arma
	fire_tween = create_tween()
	
	## Cálculo del demonio, podría haber sido mucho más sencillo utilizando
	## vectores y sacando los ángulos circulares.
	## Lo que hace es toma el ángulo relativo más cercano, ya que después de cierto
	## punto, en vez de rotar correctamente hacia arriba, da toda la vuelta.
#	var final_angle: float = deg2rad(-90.0 + 360.0 * float(rotation > deg2rad(90)))
	
	## Me enculé y lo hice de esta manera. Parece chino también, pero básicamente
	## toma un vector con rotación 0 (los radianes SIEMPRE toman como rotación 0
	## mirar a la derecha, osea, (1, 0)) y le aplica la rotación actual, le pide el ángulo
	## hacia la dirección que queremos que vaya, y luego se lo suma a la rotación actual.
	var final_angle: float = (
		rotation +
		Vector2.LEFT.rotated(rotation).angle_to(Vector2.DOWN)
	)
	
	## Y acá se anima programáticamente utilizando el ángulo actual del arma hacia
	## el ángulo final al que debe rotar.
	fire_tween.tween_property(
		self,
		"rotation",
		final_angle,
		0.5
	).set_delay(0.5)
