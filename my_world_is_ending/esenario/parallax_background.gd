extends ParallaxBackground

@export var velocidad_parallax: float = 200  # Más rápido
@export var acelerar_con_player: bool = true  # Opcional: acelera cuando el player se mueve

# Opcional: Referencia al player para acelerar parallax
@export var player_node: Node2D

func _process(delta: float) -> void:
	var velocidad_final = velocidad_parallax
	
	# Opcional: Acelerar parallax cuando el player se mueve
	if acelerar_con_player and player_node:
		var player_velocidad = abs(player_node.velocity.x)
		velocidad_final += player_velocidad * 0.5
	
	scroll_offset.x -= velocidad_final * delta
