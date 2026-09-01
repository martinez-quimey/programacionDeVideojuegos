
extends Node2D

#func new_game():
##
	#
	#$Player.start($StartPosition.position)
	#$StartTimer.start() 
func new_game():
	print("========== NEW GAME ==========")
	
	

#



func _ready() -> void:
	print("MAIN: ", self)
	print("PLAYER: ", get_node_or_null("Player"))
	print("START: ", get_node_or_null("StartPosition"))
	$HUD.start_game.connect(new_game)
	
