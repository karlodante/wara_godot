extends CharacterBody2D


@export var speed: float = 300
@export var jump_force: float = 400
@export var gravity: float = 980

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	animated_sprite.play("idle")

func _physics_process(delta):
	# Aplicar gravedad
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Saltar
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = -jump_force
		animated_sprite.play("jump")
	
	# Movimiento horizontal
	var direction = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * speed
	
	move_and_slide()
	
	# Animaciones
	handle_animations(direction)

func handle_animations(direction):
	if is_on_floor():
		if direction != 0:
			animated_sprite.play("walk")
			animated_sprite.flip_h = direction < 0
		else:
			animated_sprite.play("idle")
	else:
		if velocity.y < 0:
			animated_sprite.play("jump")
		else:
			animated_sprite.play("fall")
