extends ParallaxBackground


#
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var velocidad =10 
	scroll_offset.x -=velocidad*delta
