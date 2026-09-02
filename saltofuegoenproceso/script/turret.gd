# turret.gd
extends StaticBody2D

@export var projectile_scene: PackedScene

@onready var fire_position: Marker2D = $FirePosition
@onready var detection_area: Area2D = $DetectionArea

var projectile_container: Node
var player
var player_in_range: bool = false


func setValues(player, projectile_container):
	self.player = player
	self.projectile_container = projectile_container


func _ready():
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	if body == player:
		player_in_range = true
		$Timer.start()


func _on_body_exited(body):
	if body == player:
		player_in_range = false
		$Timer.stop()


func _on_timer_timeout():
	if player_in_range:
		fire()


func fire():
	var projectile: Proyectile = projectile_scene.instantiate()
	projectile_container.add_child(projectile)

	projectile.set_starting_values(
		fire_position.global_position,
		(player.global_position - fire_position.global_position).normalized()
	)

	projectile.delete_requested.connect(_on_projectile_delete_requested)


func _on_projectile_delete_requested(projectile):
	projectile_container.remove_child(projectile)
	projectile.queue_free()


func morir():
	queue_free()
