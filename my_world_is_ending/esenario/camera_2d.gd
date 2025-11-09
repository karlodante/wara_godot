extends Camera2D

# CONFIGURACIÓN SHAKE
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0

# SEGUIMIENTO SUAVE
@export var target_node: Node2D
@export var smooth_speed: float = 5.0

func _ready():
	# Configurar límites si es necesario
	pass

func _process(delta):
	# SEGUIMIENTO SUAVE DEL PLAYER
	if target_node:
		global_position = global_position.lerp(target_node.global_position, smooth_speed * delta)
	
	# MANEJAR SCREEN SHAKE
	handle_screen_shake(delta)

func handle_screen_shake(delta):
	if shake_timer > 0:
		shake_timer -= delta
		
		# Calcular intensidad actual (se reduce con el tiempo)
		var current_intensity = shake_intensity * (shake_timer / shake_duration)
		
		# Aplicar offset aleatorio
		offset = Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)
		
		if shake_timer <= 0:
			# Resetear cuando termina el shake
			shake_timer = 0
			offset = Vector2.ZERO

# FUNCIÓN PARA ACTIVAR SCREEN SHAKE
func screen_shake(intensity: float, duration: float):
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration
