extends ParallaxBackground

@export var velocidad_parallax: float = 100
@export var fondos_secuenciales: Array[Texture2D]

var sprites: Array[Sprite2D] = []
var indice_fondo_actual: int = 0
var ancho_pantalla: float = 1152

func _ready():
	# Buscar TODOS los sprites en el ParallaxLayer
	var parallax_layer = $ParallaxLayer
	
	for i in range(fondos_secuenciales.size()):
		var nuevo_sprite = Sprite2D.new()
		nuevo_sprite.texture = fondos_secuenciales[i]
		nuevo_sprite.position.x = i * ancho_pantalla  # Posicionar uno al lado del otro
		parallax_layer.add_child(nuevo_sprite)
		sprites.append(nuevo_sprite)
		print("✅ Fondo ", i, " posicionado en x: ", nuevo_sprite.position.x)

func _process(delta: float) -> void:
	scroll_offset.x -= velocidad_parallax * delta
	
	# Cambiar fondo activo basado en la posición
	var fondo_visible = int(abs(scroll_offset.x) / ancho_pantalla)
	
	if fondo_visible != indice_fondo_actual and fondo_visible < fondos_secuenciales.size():
		indice_fondo_actual = fondo_visible
		print("🎨 Fondo activo: ", indice_fondo_actual)
	
	# Detener si llegamos al final
	if abs(scroll_offset.x) >= ancho_pantalla * (fondos_secuenciales.size() - 0.5):
		print("🏁 Fin de los fondos")
		set_process(false)
