extends StaticBody2D

@export var projectile_scene: PackedScene
@onready var Invulnerabilidad: Timer = $Invulnerabilidad
@onready var fire_position: Marker2D = $FirePosition
@onready var detection_area: Area2D = $DetectionArea
const isBoss = false
var vida: int = 1

var projectile_container: Node
var player_in_range: bool = false


func setValues(projectile_container):
	self.projectile_container = projectile_container


func _ready():
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	if body.is_in_group("jugador"):
		player_in_range = true
		$Timer.start()


func _on_body_exited(body):
	if body.is_in_group("jugador"):
		player_in_range = false
		$Timer.stop()


func _on_timer_timeout():
	if player_in_range:
		fire()


func fire():
	var bodies = detection_area.get_overlapping_bodies()

	for body in bodies:
		if body.is_in_group("jugador"):
			var projectile: AbstractProyectile = projectile_scene.instantiate()
			projectile_container.add_child(projectile)

			projectile.set_starting_values(
				fire_position.global_position,
				(body.global_position - fire_position.global_position).normalized()
			)

			projectile.delete_requested.connect(_on_projectile_delete_requested)
			return


func _on_projectile_delete_requested(projectile):
	projectile_container.remove_child(projectile)
	projectile.queue_free()


func animacionHerida():
	while not Invulnerabilidad.is_stopped():
		$AnimatedSprite2D.visible = false
		await get_tree().create_timer(0.1).timeout
		$AnimatedSprite2D.visible = true
		await get_tree().create_timer(0.1).timeout


func morir():
	queue_free()


func herir(num: int):
	if Invulnerabilidad.is_stopped():
		vida -= num

		if isBoss:
			pass

		if vida <= 0:
			morir()
			return

		Invulnerabilidad.start()
		animacionHerida()
