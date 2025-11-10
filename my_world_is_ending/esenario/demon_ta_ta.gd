extends CharacterBody2D

# CONFIGURACIÓN DEL ENEMIGO
@export var vida_maxima: int = 50
@export var damage_ataque: int = 15
@export var velocidad: float = 80.0
@export var rango_deteccion: float = 200.0
@export var tiempo_entre_ataques: float = 2.0

# VARIABLES
var vida_actual: int
var jugador: Node2D
var puede_atacar: bool = true
var esta_muerto: bool = false

func _ready():
	vida_actual = vida_maxima
	# Buscar jugador
	buscar_jugador()
	print("👹 Enemigo listo - Vida: ", vida_actual)

func buscar_jugador():
	jugador = get_tree().get_first_node_in_group("player")
	if not jugador:
		jugador = get_tree().get_current_scene().find_child("Player", true, false)


	

	
	# CALCULAR DISTANCIA AL JUGADOR
	var distancia = global_position.distance_to(jugador.global_position)
	
	if distancia <= 40.0 and puede_atacar:  # Rango de ataque cercano
		# ATAQUE MELEE
		atacar()
	elif distancia <= rango_deteccion:
		# PERSEGUIR JUGADOR
		perseguir_jugador()
	else:
		# ESTAR QUIETO
		velocity = Vector2.ZERO
	
	move_and_slide()

func perseguir_jugador():
	var direccion = (jugador.global_position - global_position).normalized()
	velocity = direccion * velocidad
	
	# Animación básica - usar lo que tenga
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.flip_h = direccion.x < 0

func atacar():
	if not puede_atacar:
		return
	
	puede_atacar = false
	velocity = Vector2.ZERO
	
	print("👹 Enemigo atacando!")
	
	# APLICAR DAÑO AL JUGADOR
	var distancia = global_position.distance_to(jugador.global_position)
	if distancia <= 50.0 and jugador.has_method("recibir_danio"):
		var direccion_knockback = (jugador.global_position - global_position).normalized()
		jugador.recibir_danio(damage_ataque, direccion_knockback)
	
	# COOLDOWN ENTRE ATAQUES
	await get_tree().create_timer(tiempo_entre_ataques).timeout
	puede_atacar = true

# SISTEMA DE DAÑO DEL ENEMIGO
func recibir_danio(cantidad: int, direccion_knockback: Vector2 = Vector2.ZERO):
	if esta_muerto:
		return
	
	vida_actual -= cantidad
	print("🎯 Enemigo golpeado: ", cantidad, " - Vida: ", vida_actual, "/", vida_maxima)
	
	# KNOCKBACK
	velocity = direccion_knockback * 300
	
	# EFECTO VISUAL
	efecto_danio()
	
	# VERIFICAR MUERTE
	if vida_actual <= 0:
		morir()

func efecto_danio():
	# Efecto de parpadeo en rojo
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func morir():
	esta_muerto = true
	print("💀 Enemigo murió")
	
	# Desactivar colisiones
	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = true
	
	# Hacer invisible y eliminar después
	visible = false
	await get_tree().create_timer(0.5).timeout
	queue_free()
	
