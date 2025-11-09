extends CharacterBody2D

@export var speed: float = 300
@export var jump_force: float = 400
@export var dash_speed: float = 800
@export var dash_duration: float = 0.15
@export var gravity: float = 980

var is_dashing: bool = false
var dash_timer: float = 0
var dash_direction: float = 1

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	animated_sprite.play("idle")

func _physics_process(delta):
	# Manejar dash
	handle_dash(delta)
	
	# Gravedad
	if not is_on_floor() and not is_dashing:
		velocity.y += gravity * delta
	
	# Movimiento normal (solo si no está en dash)
	if not is_dashing:
		var direction = Input.get_axis("ui_left", "ui_right")
		velocity.x = direction * speed
		
		# Actualizar dirección para el dash
		if direction != 0:
			dash_direction = direction
		
		# Saltar
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = -jump_force
			animated_sprite.play("jump")
		
		# Iniciar dash (con verificación de que la acción existe)
		if Input.is_action_just_pressed("dash") and direction != 0:
			start_dash()
	
	move_and_slide()
	
	# Animaciones
	handle_animations()

func start_dash():
	is_dashing = true
	dash_timer = dash_duration
	velocity.x = dash_direction * dash_speed
	velocity.y = 0  # Resetear gravedad durante dash
	animated_sprite.play("dash")
	animated_sprite.flip_h = dash_direction < 0

func handle_dash(delta: float):
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false

func handle_animations():
	if is_dashing:
		# Durante el dash, mantener animación "dash"
		return
	
	if is_on_floor():
		if abs(velocity.x) > 0:
			animated_sprite.play("walk")
			animated_sprite.flip_h = velocity.x < 0
		else:
			animated_sprite.play("idle")
	else:
		animated_sprite.play("jump")
