#turret
extends StaticBody2D
@export var projectile_scene: PackedScene

@onready var fire_position: Marker2D = $FirePosition
var projectile_container:Node
var player


func setValues(player,projectile_container):
	self.player = player
	self.projectile_container = projectile_container 
	$Timer.start()
	



func _on_timer_timeout():
	fire()
	
func fire():
	var projectile:Proyectile = projectile_scene.instantiate()
	projectile_container.add_child(projectile)
	projectile.set_starting_values(fire_position.global_position, (player.global_position -fire_position.global_position).normalized())
	projectile.delete_requested.connect(_on_projectile_delete_requested)
	
func _on_projectile_delete_requested(projectile):
	projectile_container.remove_child(projectile)
	projectile.queue_free()
func morir():
	queue_free()
