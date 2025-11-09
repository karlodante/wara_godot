extends ParallaxBackground

@export var velocidad_parallax: float = 100

func _process(delta: float) -> void:
	scroll_base_offset.x -= velocidad_parallax * delta
