extends CharacterBody2D

@export var jugador: Node  # ⬅️ ARRASTRA TU JUGADOR AQUÍ
@export var velocidad: float = 120.0

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	if jugador:
		print("✅ Dron conectado a: ", jugador.name)
	else:
		print("❌ ARRASTRA el jugador al dron en el Inspector!")

func _physics_process(delta):
	if not jugador:
		return
	
	# Seguir al jugador
	var target_pos = jugador.global_position + Vector2(40, -30)
	global_position = global_position.lerp(target_pos, delta * 2.0)
	
	# ANIMACIÓN SEGURA - usa la primera animación disponible
	play_animacion_segura()
	
	# Dirección visual
	animated_sprite.flip_h = global_position.x < jugador.global_position.x

func play_animacion_segura():
	# Verificar qué animaciones existen y usar la primera disponible
	var animaciones = animated_sprite.sprite_frames.get_animation_names()
	
	if animaciones.size() > 0:
		# Usar la primera animación disponible
		var anim_actual = animaciones[0]
		if animated_sprite.animation != anim_actual:
			animated_sprite.play(anim_actual)
	else:
		print("⚠️ Dron: No hay animaciones configuradas")

# Flotación
func _process(delta):
	position.y += sin(Time.get_ticks_msec() * 0.004) * delta * 5
