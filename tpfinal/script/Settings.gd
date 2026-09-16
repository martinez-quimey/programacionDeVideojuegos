#settings
extends Node

var language: String = "es"
var sePuedePausar = false
var main = null
func setearMain (Main):
	main = Main
	
func getMain ():
	return main
